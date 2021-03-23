## Connection setting overlays

There may be cases where you want to use a different set of connection settings
depending on context. For example, if you want to use username and password
provided by the user in a web application. Since `.fmrest_config` is set at the
class level, changing the username/password for the model in one context would
also change it in all other contexts, leading to security issues.

fmrest-ruby solves this scenario with the following methods:

### FmRest::Layout.fmrest_config_overlay=

`.fmrest_config_overlay=` allows you to override some settings in a
thread-local and reversible manner. That way, using the same scenario as above,
you could connect to the Data API with user-provided credentials without having
them leak into other users of your web app.

E.g.:

```ruby
class BeeBase < FmRest::Layout
  # Host and database provided as base settings
  self.fmrest_config = {
    host:     "example.com",
    database: "My Database"
  }
end

# Example context: a controller action of a Rails application

# User-provided credentials
BeeBase.fmrest_config_overlay = {
  username: params[:username],
  password: params[:password]
}

# Perform some Data API requests ...
```

### FmRest::Layout.clear_fmrest_config_overlay

Clears the thread-local settings provided to `.fmrest_config_overaly=`.

### FmRest::Layout.with_overlay

Runs a block with the given settings overlay, resetting them after the block
finishes running. It wraps execution in its own fiber, so it doesn't affect the
overlay of the currently-running thread.

```ruby
Honeybee.with_overlay(username: "...", password: "...") do
  Honeybee.query(...)
end
```
