## Base connection usage (without ORM)

This document describes using the base Faraday connection provided by
`fmrest-core`. If you want the ORM features refer back to the
[README](../README.md) and `fmrest-spyke`.

To get a Faraday connection that handles the Data API authentication workflow
and encodes/decodes JSON automatically:

```ruby
connection = FmRest::V1.build_connection(
  host:     "example.com",
  database: "database name",
  username: "username",
  password: "password"
)
```

See the README for the full list of supported connection settings.

The returned connection will prefix any non-absolute paths with
`"/fmi/data/v1/databases/:database/"`, so you only need to supply the
meaningful part of the path (e.g. `"layouts/MyLayout/records"`).

To send a request to the Data API use Faraday's standard methods, e.g.:

```ruby
# Get all records
connection.get("layouts/MyLayout/records")

# Create new record
connection.post do |req|
  req.url "layouts/MyLayout/records"

  # You can just pass a hash for the JSON body
  req.body = { ... }
end
```

For each request fmrest-ruby will first request a session token (using the
provided username and password) if it doesn't yet have one in store.

### Logging out of the database session

The Data API requires sending a DELETE request to
`/fmi/data/:version/databases/:database_name/sessions/:session_token`
in order to log out from the session
([see docs](https://fmhelp.filemaker.com/docs/18/en/dataapi/#connect-database_log-out)).

Since fmrest-ruby handles the storage of session tokens internally, and the
token is required to build the logout URL, this becomes a non-trivial action.

To remedy this, fmrest-ruby connections recognize when you're trying to logout
and substitute whatever is in the `:session_token` section of the logout path
with the actual session token:

```ruby
# Logout from the database session
connection.delete "sessions/this-will-be-replaced-with-the-actual-token"
```

NOTE: If you're using the ORM features this becomes much more straight-forward,
see `FmRest::Layout.logout`.
