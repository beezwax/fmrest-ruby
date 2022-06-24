## Changelog

### 0.22.0

* Add `fmrest-rails` gem with Rails integration (initializer, generators)

### 0.21.0

* Support for Spyke 7 and Faraday 2
* Drop support for Faraday 1
* Drop support for Ruby 2.5

### 0.20.0

* Forward proxy options to AWS Client when using `fmrest-cloud` gem

### 0.19.0

* Added native support for FileMaker Cloud through the `fmrest-cloud` gem

### 0.18.0

* Better support for portals with mismatching field qualifiers
* Better ergonomics for script execution, improved documentation
* Defining an attribute on a model that would collide with an existing method
  now raises an error
* Cleared Faraday deprecation messages on authentication methods
* Handle FileMaker Cloud case where HTTP 401 Unauthorized with content-type
  text/html is returned after token expiry
* Add retry option to Rescuable mixin
* Added fmrest-ruby/VERSION to User-Agent headers

### 0.17.1

* Fixed crash when `fmid_token` is set but `username` isn't

### 0.17.0

* Added support for Claris ID token login
* Added ability to use procs in settings
* Added `Rescuable` mixin

### 0.16.0

* Added `FmRest.logger=`
* Handle serialization of `nil`, `true` and `false` values

### 0.15.2

* Fixed autoloading of `FmRest::Layout`

### 0.15.0

* Much improved querying API (see documentation on querying), adding new
  `.query` capabilities, as well as two new methods: `.match` and `.or`

### 0.14.0

* Aliased `FmRest::Spyke::Base` as `FmRest::Layout` (now preferred), and
  provided a shortcut version for setting the layout name (e.g.  `class Foo <
  FmRest::Layout("LayoutName")`)
* Made `layout` class setting subclass-inheritable

### 0.13.1

* Fixed downloading of container field data from FMS19+

### 0.13.0

* Split `fmrest` gem into `fmrest-core` and `fmrest-spyke`. `fmrest` becomes a
  wrapper for the two new gems.
* Fixed bug preventing connection databases with spaces in their names.
* Improved portal support with ability to delete portal records, and better
  refreshing of portal records after saving the parent.
* `FmRest::Spyke::Base#__record_id` and `FmRest::Spyke::Base#__mod_id` now
  always return integers if set.

### 0.12.0

* Rename `FmRest::Spyke::Base#id=` to `FmRest::Spyke::Base#__record_id=` to
  prevent clobbering of FileMaker layout-defined fields
* Removed previously deprecated `FmRest::Spyke::Base(config)` syntax
* Better yard documentation

### 0.11.1

* Fixed a couple crashes due to missing constants

### 0.11.0

* Added custom class for connection settings, providing indifferent access
  (i.e. keys can be strings or symbols), and centralized default values and
  validations
* Added `:autologin`, `:token` and `:token_store` connection settings
* Added `FmRest::Base.fmrest_config_overlay=` and related methods
* Added `FmRest::V1.request_auth_token` and
  `FmRest::Spyke::Base.request_auth_token` (as well as `!`-suffixed versions
  which raise exceptions on failure)

### 0.10.1

* Fixed `URI.escape` obsolete warning messages in Ruby 2.7 by replacing it with
  `URI.encode_www_form_component`
  ([PR#40](https://github.com/beezwax/fmrest-ruby/pull/40))

### 0.10.0

* Added `FmRest::StringDateAwareness` module to correct some issues when using
  `FmRest::StringDate`
* Added basic timezones support
* Deprecated `class < FmRest::Spyke::Base(config_hash)` syntax in favor of
  using `self.fmrest_config=`

### 0.9.0

* Added `FmRest::Spyke::Base.set_globals`

### 0.8.0

* Improved metadata when using `FmRest::Spyke::Model`. Metadata now uses
  Struct/OpenStruct, so properties are accessible through `.property`, as well
  as `[:property]`
* Added batch-finders `.find_in_batches` and `.find_each` for
* `FmRest::Spyke::Base`

### 0.7.1

* Made sure `Model.find_one` and `Model.find_some` work without needing to call
  `Model.all` in between

### 0.7.0

* Added date coercion feature

### 0.6.0

* Implemented session logout
  ([#16](https://github.com/beezwax/fmrest-ruby/issues/16))

### 0.5.2

* Improved support for legacy ActiveModel 4.x

### 0.5.1

* Alias `:username` option as `:account_name` for ginjo-rfm gem
  cross-compatibility

### 0.5.0

* Much improved script execution support
  ([#20](https://github.com/beezwax/fmrest-ruby/issues/20))
* Fixed bug when setting `default_limi` and trying to find a record
  ([35](https://github.com/beezwax/fmrest-ruby/issues/35))

### 0.4.1

* Prevent raising an exception when a /\_find request yields no results
  ([#33](https://github.com/beezwax/fmrest-ruby/issues/33) and
  [#34](https://github.com/beezwax/fmrest-ruby/issues/34))

### 0.4.0

* Implement ability to set limit and offset for portals
* Implement disabling and requesting all portals

### 0.3.3

* Fix encoding of paths for layouts with brackets in them (e.g. `"\[Very Ugly\]
  Layout"`)
* Raise an error if `"id"` is assigned as an attribute on a model, as it's
  currently a reserved method name by Spyke

### 0.3.2

* Fixed support for ActiveSupport < 5.2
  ([#27](https://github.com/beezwax/fmrest-ruby/issues/27))

### 0.3.0

* Added Moneta token store

### 0.2.5

* Fixed crash in `fetch_container_data` when no proxy options were set

### 0.2.4

* Use `String#=~` instead of `String#match?` for Ruby <2.4 compatibility (Fixes
  [#26](https://github.com/beezwax/fmrest-ruby/issues/26))
* Deprecated `FmRest.config` in favor of `FmRest.default_connection_settings`
* Honor Faraday SSL and proxy settings when fetching container files
