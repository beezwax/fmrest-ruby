## Connecting to FileMaker Cloud

When using FileMaker Cloud the Data API uses a [different authentication
workflow](https://help.claris.com/en/data-api-guide/#connect-database_log-in-fmid)
than that of a self-hosted FileMaker Server. Instead of FileMaker Cloud
handling username/password authentication directly, one must authenticate using
[AWS Cognito](https://aws.amazon.com/cognito/) first to obtain a *Claris ID
token* (also known as *FMID token*).

fmrest-ruby currently supports authenticating with an existing Claris ID token,
but it doesn't yet support the [AWS Cognito authentication and token fetching
step](https://help.claris.com/en/customer-console-help/content/create-fmid-token.html),
which has to be handled manually. But feat not, this document provides an
example implementation (just keep reading).

If you already have a valid Claris ID token, you can pass it in fmrest-ruby's
settings as `:fmid_token`, and omit `:username` and `:password`.

Since Claris ID tokens are only valid an hour you can't just set `:fmid_token`
in a static config file. Instead, you can use a proc to define how the Claris
ID token should be fetched each time, e.g.:

```ruby
class MyLayout < FmRest::Layout
  self.fmrest_config = {
    host:       "…",
    database:   "…",
    fmid_token: -> { ClarisIdTokenManager.fetch_token }
  }
end
```

Where `ClarisIdTokenManager` is a class or module you define yourself that
manages the Amazon Cognito and token persistance logic.

To handle Claris ID token expiration you can wrap your Data API calls in a
`begin...rescue` block and capture `FmRest::APIError::AccountError`
exceptions:

```ruby
begin
  r = MyLayout.find_one
rescue FmRest::APIError::AccountError
  ClarisIDTokenManager.expire_token
  retry
end
```

As a convenient shorthand for the above you can choose to use the `Rescuable`
mixin in your `FmRest::Layout` class. E.g.:

```ruby
class BaseLayout < FmRest::Layout
  # Rescuable is not mixed-in by default
  include FmRest::Spyke::Model::Rescuable

  # Shorthand for rescue_with FmRest::APIError::AccountError, ...
  rescue_account_error { ClarisIDTokenManager.expire_token }
end
```

### Full implementation example

Below are all the pieces of a full FileMaker Cloud auth implementation,
including AWS Cognito authentication. This assumes a Rails project for the
folder structure, but the same can be applied to non-Rails projects as well
with minimal modifications.

Gemfile:

```ruby
# ...
gem 'fmrest'
gem 'aws-sdk-cognitoidentityprovider'
```

app/models/application_fm_layout.rb:

```ruby
# frozen_string_literal: true

# All other layout models should inherit from this
#
class ApplicationFmLayout < FmRest::Layout
  # Rescuable is not mixed-in by default
  include FmRest::Spyke::Model::Rescuable

  # Shorthand for rescue_with FmRest::APIError::AccountError, ...
  rescue_account_error { ClarisIdTokenManager.expire_token }

  # Load FileMaker connection settings from config/filemaker.yml
  @fm_config = Rails.application.config_for(:filemaker)

  self.fmrest_config = {
    host:       @fm_config.fetch(:host),
    database:   @fm_config.fetch(:database),
    log:        @fm_config.fetch(:log, false),
    fmid_token: -> { ClarisIdTokenManager.fetch_token }
  }
end
```

app/services/claris_id_token_manager.rb:

```ruby
# frozen_string_literal: true

require "aws/cognito_srp"

module ClarisIdTokenManager
  CLIENT_ID = "4l9rvl4mv5es1eep1qe97cautn"
  POOL_ID = "us-west-2_NqkuZcXQY"
  REGION = "us-west-2"

  TOKEN_STORE_PREFIX = "cognito"

  class << self
    def fetch_token
      if token = token_store.load(token_store_key)
        return token
      end

      tokens = get_cognito_tokens

      token_store.store(token_store_key, tokens.id_token)
      token_store.store(token_store_key(:refresh), tokens.refresh_token) if tokens.refresh_token

      tokens.id_token
    end

    def expire_token
      token_store.delete(token_store_key)
    end

    private

    def get_cognito_tokens
      # Use refresh mechanism first if we have a refresh token
      refresh_cognito_token || cognito_srp_client.authenticate
    end

    def refresh_cognito_token
      return unless refresh_token = token_store.load(token_store_key(:refresh))

      begin
        resp = aws_client.initiate_auth(
          client_id: CLIENT_ID,
          auth_flow: "REFRESH_TOKEN",
          auth_parameters: {
            REFRESH_TOKEN: refresh_token
          }
        )
      rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
        return nil
      end

      resp.authentication_result
    end

    def cognito_srp_client
      @cognito_srp_client ||=
        Aws::CognitoSrp.new(
          username: fm_config.fetch(:username),
          password: fm_config.fetch(:password),
          pool_id: POOL_ID,
          client_id: CLIENT_ID,
          aws_client: aws_client
        )
    end

    def fm_config
      @fm_config ||= Rails.application.config_for(:filemaker)
    end

    def aws_client
      @aws_client ||= Aws::CognitoIdentityProvider::Client.new(region: REGION)
    end

    def token_store_key(token_type = :id)
      "#{TOKEN_STORE_PREFIX}:#{token_type}:#{fm_config.fetch(:username)}"
    end

    def token_store
      @token_store ||= FmRest.token_store
    end
  end
end
```

lib/aws/cognito_srp.rb:

```ruby
# frozen_string_literal: true

require "aws-sdk-cognitoidentityprovider"

module Aws
  # Client for AWS Cognito Identity Provider using Secure Remote Password (SRP).
  #
  # Borrowed from:
  # https://gist.github.com/jviney/5fd0fab96cd70d5d46853f052be4744c
  #
  # This code is a direct translation of the Python version found here:
  # https://github.com/capless/warrant/blob/ff2e4793d8479e770f2461ef7cbc0c15ee784395/warrant/aws_srp.py
  #
  # Example usage:
  #
  #   aws_srp = Aws::CognitoSrp.new(
  #     username: "username",
  #     password: "password",
  #     pool_id: "pool-id",
  #     client_id: "client-id",
  #     aws_client: Aws::CognitoIdentityProvider::Client.new(region: "us-west-2")
  #   )
  #
  #   aws_srp.authenticate
  #
  class CognitoSrp
    def initialize(username:, password:, pool_id:, client_id:, aws_client:)
      @username = username
      @password = password
      @pool_id = pool_id
      @client_id = client_id
      @aws_client = aws_client

      @big_n = hex_to_long(N_HEX)
      @g = hex_to_long(G_HEX)
      @k = hex_to_long(hex_hash("00#{N_HEX}0#{G_HEX}"))
      @small_a_value = generate_random_small_a
      @large_a_value = calculate_a
    end

    def authenticate
      init_auth_response = @aws_client.initiate_auth(
        client_id: @client_id,
        auth_flow: "USER_SRP_AUTH",
        auth_parameters: {
          "USERNAME" => @username,
          "SRP_A" => long_to_hex(@large_a_value)
        }
      )

      raise unless init_auth_response.challenge_name == "PASSWORD_VERIFIER"

      challenge_response = process_challenge(init_auth_response.challenge_parameters)

      auth_response = @aws_client.respond_to_auth_challenge(
        client_id: @client_id,
        challenge_name: "PASSWORD_VERIFIER",
        challenge_responses: challenge_response
      )

      raise "new password required" if auth_response.challenge_name == "NEW_PASSWORD_REQUIRED"

      auth_response.authentication_result
    end

    private

    def generate_random_small_a
      random_long_int = get_random(128)
      random_long_int % @big_n
    end

    def calculate_a
      big_a = @g.pow(@small_a_value, @big_n)
      if big_a % @big_n == 0
        raise "Safety check for A failed"
      end

      big_a
    end

    def get_password_authentication_key(username, password, server_b_value, salt)
      u_value = calculate_u(@large_a_value, server_b_value)
      if u_value == 0
        raise "U cannot be zero."
      end

      username_password = "#{@pool_id.split("_")[1]}#{username}:#{password}"
      username_password_hash = hash_sha256(username_password)

      x_value = hex_to_long(hex_hash(pad_hex(salt) + username_password_hash))
      g_mod_pow_xn = @g.pow(x_value, @big_n)
      int_value2 = server_b_value - @k * g_mod_pow_xn
      s_value = int_value2.pow(@small_a_value + u_value * x_value, @big_n)
      hkdf = compute_hkdf(hex_to_bytes(pad_hex(s_value)), hex_to_bytes(pad_hex(long_to_hex(u_value))))
      hkdf
    end

    def process_challenge(challenge_parameters)
      user_id_for_srp = challenge_parameters.fetch("USER_ID_FOR_SRP")
      salt_hex = challenge_parameters.fetch("SALT")
      srp_b_hex = challenge_parameters.fetch("SRP_B")
      secret_block_b64 = challenge_parameters.fetch("SECRET_BLOCK")

      timestamp = Time.now.utc.strftime("%a %b %-d %H:%M:%S %Z %Y")

      hkdf = get_password_authentication_key(user_id_for_srp, @password, srp_b_hex.to_i(16), salt_hex)
      secret_block_bytes = Base64.strict_decode64(secret_block_b64)
      msg = @pool_id.split("_")[1] + user_id_for_srp + secret_block_bytes + timestamp
      hmac_digest = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), hkdf, msg)
      signature_string = Base64.strict_encode64(hmac_digest).force_encoding('utf-8')

      {
        "TIMESTAMP" => timestamp,
        "USERNAME" => user_id_for_srp,
        "PASSWORD_CLAIM_SECRET_BLOCK" => secret_block_b64,
        "PASSWORD_CLAIM_SIGNATURE" => signature_string
      }
    end

    N_HEX = %w(
      FFFFFFFF FFFFFFFF C90FDAA2 2168C234 C4C6628B 80DC1CD1 29024E08
      8A67CC74 020BBEA6 3B139B22 514A0879 8E3404DD EF9519B3 CD3A431B
      302B0A6D F25F1437 4FE1356D 6D51C245 E485B576 625E7EC6 F44C42E9
      A637ED6B 0BFF5CB6 F406B7ED EE386BFB 5A899FA5 AE9F2411 7C4B1FE6
      49286651 ECE45B3D C2007CB8 A163BF05 98DA4836 1C55D39A 69163FA8
      FD24CF5F 83655D23 DCA3AD96 1C62F356 208552BB 9ED52907 7096966D
      670C354E 4ABC9804 F1746C08 CA18217C 32905E46 2E36CE3B E39E772C
      180E8603 9B2783A2 EC07A28F B5C55DF0 6F4C52C9 DE2BCBF6 95581718
      3995497C EA956AE5 15D22618 98FA0510 15728E5A 8AAAC42D AD33170D
      04507A33 A85521AB DF1CBA64 ECFB8504 58DBEF0A 8AEA7157 5D060C7D
      B3970F85 A6E1E4C7 ABF5AE8C DB0933D7 1E8C94E0 4A25619D CEE3D226
      1AD2EE6B F12FFA06 D98A0864 D8760273 3EC86A64 521F2B18 177B200C
      BBE11757 7A615D6C 770988C0 BAD946E2 08E24FA0 74E5AB31 43DB5BFC
      E0FD108E 4B82D120 A93AD2CA FFFFFFFF FFFFFFFF
    ).join.freeze

    G_HEX = '2'

    INFO_BITS = 'Caldera Derived Key'

    def hash_sha256(buf)
      a = Digest::SHA256.hexdigest(buf)
      raise unless a.size == 64
      a
    end

    def hex_hash(hex_string)
      hash_sha256(hex_to_bytes(hex_string))
    end

    def hex_to_bytes(hex_string)
      [hex_string].pack('H*')
    end

    def bytes_to_hex(bytes)
      bytes.unpack1('H*')
    end

    def hex_to_long(hex_string)
      hex_string.to_i(16)
    end

    def long_to_hex(long_num)
      long_num.to_s(16)
    end

    def get_random(nbytes)
      random_hex = bytes_to_hex(SecureRandom.bytes(nbytes))
      hex_to_long(random_hex)
    end

    def pad_hex(long_int)
      hash_str = if long_int.is_a?(String)
        long_int
      else
        long_to_hex(long_int)
      end

      if hash_str.size % 2 == 1
        hash_str = "0#{hash_str}"
      elsif '89ABCDEFabcdef'.include?(hash_str[0])
        hash_str = "00#{hash_str}"
      end

      hash_str
    end

    def compute_hkdf(ikm, salt)
      prk = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), salt, ikm)
      info_bits_update = INFO_BITS + 1.chr.force_encoding('utf-8')
      hmac_hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), prk, info_bits_update)
      hmac_hash[0, 16]
    end

    def calculate_u(big_a, big_b)
      u_hex_hash = hex_hash(pad_hex(big_a) + pad_hex(big_b))
      hex_to_long(u_hex_hash)
    end
  end
end
```

config/filemaker.yml:

```yml
development:
  host: YOUR-FILEMAKER-CLOUD-SUBDOMAIN.account.filemaker-cloud.com
  database:
  username: YOUR-CLARIS-ACCOUNT
  password: YOUR-CLARIS-PASSWORD
  log: true

production:
  host: YOUR-FILEMAKER-CLOUD-SUBDOMAIN.account.filemaker-cloud.com
  database:
  username: YOUR-CLARIS-ACCOUNT
  password: YOUR-CLARIS-PASSWORD
```
