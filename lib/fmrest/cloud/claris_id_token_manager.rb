# frozen_string_literal: true

require "aws-cognito-srp"

module FmRest
  module Cloud
    class ClarisIdTokenManager
      include TokenStore

      COGNITO_CLIENT_ID = "4l9rvl4mv5es1eep1qe97cautn"
      COGNITO_POOL_ID = "us-west-2_NqkuZcXQY"
      AWS_REGION = "us-west-2"

      TOKEN_STORE_PREFIX = "claris-cognito"

      def initialize(settings)
        @settings = settings
      end

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
          cognito_srp_client.refresh_tokens(refresh_token)
        rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
          nil
        end
      end

      def cognito_srp_client
        @cognito_srp_client ||=
          Aws::CognitoSrp.new(
            username: @settings.username!,
            password: @settings.password!,
            pool_id: @settings.cognito_pool_id || COGNITO_POOL_ID,
            client_id: @settings.cognito_client_id || COGNITO_CLIENT_ID,
            aws_client: build_aws_client
          )
      end

      def build_aws_client
        options = { region: @settings.aws_region || AWS_REGION }
        options[:http_proxy] = @settings.proxy if @settings.proxy?
        Aws::CognitoIdentityProvider::Client.new(options)
      end

      def token_store_key(token_type = :id)
        "#{TOKEN_STORE_PREFIX}:#{token_type}:#{@settings.username!}"
      end

      def token_store_option
        @settings.token_store || FmRest.token_store
      end
    end
  end
end
