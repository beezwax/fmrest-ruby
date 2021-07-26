## Connecting to FileMaker Cloud

If you're using FileMaker Cloud you may need to log in using a Claris ID
account instead of the regular username and password (see the [Data API
documentation on connecting using a Claris
ID](https://help.claris.com/en/data-api-guide/#connect-database_log-in-fmid)).

In that case, pass `:fmid_token` with the token you obtained from [Amazon
Cognito](https://help.claris.com/en/customer-console-help/content/create-fmid-token.html)
in your connection settings and simply omit `:username` and `:password`.

Note that fmrest-ruby will not obtain a Claris ID token for you as that falls
outside the scope of this gem, so you'll have to obtain, persist and handle the
expiration and renewal of your Claris ID token yourself. Take a look at the
[AWS SDK for Ruby](https://github.com/aws/aws-sdk-ruby) for gems you can use to
communicate with Amazon Cognito.

Since Claris ID tokens are only valid for a few hours you can't just set
`:fmid_token` in a static config file. Instead, you can use a proc to define
how the Claris ID token should be fetched each time, e.g.:

```ruby
class MyLayout < FmRest::Layout
  self.fmrest_config = {
    host:       "…",
    database:   "…",
    fmid_token: -> { ClarisIDTokenManager.fetch_token }
  }
end
```

Where `ClarisIDTokenManager` is a class or module you define yourself that
manages the Amazon Cognito and token persistance logic.

To handle Claris ID token expiration you can wrap your Data API calls in a
`begin...rescue` block and capture `FmRest::APIError::AccountError`
exceptions:

```ruby
begin
  r = MyLayout.find_one
rescue FmRest::APIError::AccountError
  ClarisIDTokenManager.expire_token
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
