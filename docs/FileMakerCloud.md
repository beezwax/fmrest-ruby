## Connecting to FileMaker Cloud

FileMaker Cloud uses a [different authentication
workflow](https://help.claris.com/en/data-api-guide/#connect-database_log-in-fmid)
for the Data API than that of a self-hosted FileMaker Server, using [AWS
Cognito](https://aws.amazon.com/cognito/).

Because of this, and to avoid bringing in unnecessary dependencies, fmrest-ruby
adds support to FileMaker Cloud through the separate `fmrest-cloud` gem, which
you should add to your Gemfile in addition to the regular `fmrest`:

```ruby
gem 'fmrest'
gem 'fmrest-cloud'
```

With the `fmrest-cloud` gem installed, connecting to a FileMaker Cloud server
should be seamless, and you don't need to `require` any additional files.

If your FileMaker Cloud files are hosted in a `*.filemaker-cloud.com`
subdomain, then fmrest-ruby will automatically detect it and try to
authenticate using the FileMaker Cloud authentication flow. If you're using a
custom domain name however, you'll have to specify that you want to use the FM
Cloud auth flow by passing `cloud: true` in the connection settings.

The `:cloud` setting accepts these values:

`:cloud` value | Description
---------------|----------------------------------------------------------------
`:auto`        | (Default) Detect `*.filemaker-cloud.com` domains to determine which auth flow to use
`true`         | Use the FileMaker Cloud auth flow
`false`        | Use the regular FileMaker Server Data API auth flow

### Manually providing an FMID (Cognito) token

In 99.99% of cases you'd want to let `fmrest-cloud` handle the authentication
flow for you (as detailed above), but in the very rare case that you want to
handle Cognito authentication manually, you can pass the FMID token (also known
as IdToken in Cognito parlance) to fmrest-ruby with the `:fmid_token` setting,
and omit `:username` and `:password`.

Since Claris ID tokens are only valid for an hour you can't just set
`:fmid_token` in a static config file. Instead, you can use a proc to define
how the Claris ID token should be fetched each time, e.g.:

```ruby
class MyLayout < FmRest::Layout
  self.fmrest_config = {
    host:       "…",
    database:   "…",
    fmid_token: -> { MyClarisIdTokenManager.fetch_token }
  }
end
```

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
  rescue_account_error { MyClarisIDTokenManager.expire_token }
end
```

### Overwriting FileMaker Cloud's Cognito settings

FileMaker Cloud's Cognito instance is defined by these constants, which in
theory should *never* change:

```ruby
AWS_REGION = "us-west-2"
COGNITO_CLIENT_ID = "4l9rvl4mv5es1eep1qe97cautn"
COGNITO_POOL_ID = "us-west-2_NqkuZcXQY"
```

But if for any reason they did, you can overwrite them with these settings:

* `:cognito_client_id`
* `:cognito_pool_id`
* `:aws_region`
