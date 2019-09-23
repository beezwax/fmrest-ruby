## Changelog

### 0.3.2

* Fix support for ActiveSupport < 5.2
  ([#27](https://github.com/beezwax/fmrest-ruby/issues/27))

### 0.3.0

* Add Moneta token store

### 0.2.5

* Fix crash in `fetch_container_data` when no proxy options were set

### 0.2.4

* Use `String#=~` instead of `String#match?` for Ruby <2.4 compatibility (Fixes
  [#26](https://github.com/beezwax/fmrest-ruby/issues/26))
* Deprecate `FmRest.config` in favor of `FmRest.default_connection_settings`
* Honor Faraday SSL and proxy settings when fetching container files
