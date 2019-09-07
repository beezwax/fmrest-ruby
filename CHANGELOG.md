## Changelog

### 0.2.4

* Use `String#=~` instead of `String#match?` for Ruby <2.4 compatibility (Fixes
  [#26](https://github.com/beezwax/fmrest-ruby/issues/26))
* Deprecate `FmRest.config` in favor of `FmRest.default_connection_settings`
* Honor Faraday SSL and proxy settings when fetching container files
