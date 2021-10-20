# fmrest-ruby

[![Gem Version](https://badge.fury.io/rb/fmrest.svg?style=flat)](https://rubygems.org/gems/fmrest)
![CI](https://github.com/beezwax/fmrest-ruby/workflows/CI/badge.svg)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/github/beezwax/fmrest-ruby)

A Ruby client for
[FileMaker's Data API](https://help.claris.com/en/data-api-guide)
with ActiveRecord-ish ORM features.

While pretty feature-rich, fmrest-ruby doesn't yet support 100% of FileMaker
19's Data API features. See the [implementation completeness
table](#api-implementation-completeness-table) to check if a feature you need
is natively supported by the gem.

Need Ruby or FileMaker consulting? Contact us at
[Beezwax.net](https://beezwax.net/)

## Contents

* [Gems](#gems)
* [Installation](#installation)
* [Simple example](#simple-example)
* [Connection settings](#connection-settings)
* [Session token store](#session-token-store)
* [Date fields and timezones](#date-fields-and-timezones)
* [ActiveRecord-like ORM (fmrest-spyke)](#activerecord-like-orm-fmrest-spyke)
* [Logging](#logging)
* [Gotchas](#gotchas)
* [API implementation completeness table](#api-implementation-completeness-table)
* [Supported Ruby versions](#supported-ruby-versions)

## Gems

The `fmrest` gem is a wrapper for two other gems:

* `fmrest-spyke`, providing an ActiveRecord-like ORM library built on top
  of `fmrest-core` and [Spyke](https://github.com/balvig/spyke).
* `fmrest-core`, providing the core
  [Faraday](https://github.com/lostisland/faraday) connection builder, session
  management, and other core utilities.

In addition, the optional `fmrest-cloud` gem adds support for FileMaker Cloud.
See the [main document on connecting to FileMaker
Cloud](docs/FileMakerCloud.md).

## Installation

In your Gemfile:

```ruby
gem 'fmrest'

# Optional: if your files are hosted on FileMaker Cloud
gem 'fmrest-cloud'
```

## Simple example

```ruby
# A Layout model connecting to the "Honeybees Web" FileMaker layout
class Honeybee < FmRest::Layout("Honeybees Web")
  # Connection settings
  self.fmrest_config = {
    host:     "…",
    database: "…",
    username: "…",
    password: "…"
  }

  # Mapped attributes
  attributes name: "Bee Name", age: "Bee Age", created_on: "Created On"

  # Portal associations
  has_portal :tasks

  # File containers
  container :photo, field_name: "Bee Photo"

  # Scopes
  scope :can_legally_fly, -> { query(age: ">18") }

  # Client-side validations
  validates :name, presence: true

  # Callbacks
  before_save :set_created_on

  private

  def set_created_on
    self.created_on = Date.today
  end
end

# Find a record by id
bee = Honeybee.find(9)

bee.name = "Hutch"

# Add a new record to portal
bee.tasks.build(urgency: "Today")

bee.save
```

In case you don't want the ORM features (i.e. you only need authentication and
JSON parsing, and are comfortable writing the API requests manually without the
ORM overhead) you can use the Faraday connection provided by `fmrest-core`.
See the [main document on using the base
connection](docs/BaseConnectionUsage.md) for more.

## Connection settings

The minimum required connection settings are `:host`, `:database`, `:username`
and `:password`, but fmrest-ruby has many other options you can pass when
setting up a connection (see [full list](#full-list-of-available-options) below).

`:ssl` and `:proxy` are forwarded to the underlying
[Faraday](https://github.com/lostisland/faraday) connection. You can use this
to, for instance, disable SSL verification:

```ruby
{
  host: "…",
  …
  ssl:  { verify: false }
}
```

You can also pass a `:log` option for basic request logging, see the section on
[Logging](#Logging) below.

### Full list of available options

Option              | Description                                | Format                      | Default
--------------------|--------------------------------------------|-----------------------------|--------
`:host`             | Hostname with optional port, e.g. `"example.com:9000"` | String          | None
`:database`         | The name of the database to connect to     | String                      | None
`:username`         | A Data API-ready account                   | String                      | None
`:password`         | Your password                              | String                      | None
`:account_name`     | Alias of `:username`                       | String                      | None
`:ssl`              | SSL options to be forwarded to Faraday     | Faraday SSL options         | None
`:proxy`            | Proxy URI e.g. `http://username:password@proxy.host:5000` | String / URI | None
`:log`              | Log JSON responses to STDOUT               | Boolean                     | `false`
`:log_level`        | Which log level to log into                | Values accepted by `Logger#level=` | `:debug`
`:coerce_dates`     | See section on [date fields](#date-fields-and-timezones) | Boolean \| `:hybrid` \| `:full` | `false`
`:date_format`      | Date parsing format                        | String (FM date format)     | `"MM/dd/yyyy"`
`:timestamp_format` | Timestmap parsing format                   | String (FM date format)     | `"MM/dd/yyyy HH:mm:ss"`
`:time_format`      | Time parsing format                        | String (FM date format)     | `"HH:mm:ss"`
`:timezone`         | The timezone for the FM server             | `:local` \| `:utc` \| `nil` | `nil`
`:autologin`        | Whether to automatically start Data API sessions | Boolean               | `true`
`:token`            | Used to manually provide a session token (e.g. if `:autologin` is `false`) | String | None
`:fmid_token`       | Claris ID token (only needed if manually obtaining the token) | String   | None
`:cloud`            | Specifies whether the host is using FileMaker Cloud | `:auto` \| Boolean | `:auto`
`:cognito_client_id`| Overwrites the hardcoded FileMaker Cloud Cognito Client ID | String      | None
`:cognito_pool_id`  | Overwrites the hardcoded FileMaker Cloud Cognito Pool ID | String        | None
`:aws_region`       | Overwrites the hardcoded FileMaker Cloud AWS Region | String             | None

### Default connection settings

If you're only connecting to a single FM database you can configure it globally
through `FmRest.default_connection_settings=`. E.g.:

```ruby
FmRest.default_connection_settings = {
  host:     "…",
  database: "…",
  username: "…",
  password: "…"
}
```

These settings will be used by default by `FmRest::Layout` models whenever you
don't set `fmrest_config=` explicitly, as well as by
`FmRest::V1.build_connection` in case you're setting up your Faraday connection
manually.

## Session token store

fmrest-ruby includes a number of options for storing session tokens:

* Memory
* ActiveRecord
* Redis
* Moneta

See the [main document on token stores](docs/TokenStore.md) for detailed info
on how to set up each store.

## Date fields and timezones

fmrest-ruby has automatic detection and coercion of date fields to and from
Ruby date/time objects. Basic timezone support is also provided.

See the [main document on date fields](docs/DateFields.md) for more info.

## ActiveRecord-like ORM (fmrest-spyke)

[Spyke](https://github.com/balvig/spyke) is an ActiveRecord-like gem for
building REST ORM models. fmrest-ruby uses it to build its ORM features,
bundled in the `fmrest-spyke` gem (already included if you're using the
`fmrest` gem).

To create a model you can inherit directly from `FmRest::Layout` (itself a
subclass of `Spyke::Base`).

```ruby
class Honeybee < FmRest::Layout
end
```

All of Spyke's basic ORM operations work as expected:

```ruby
bee = Honeybee.new

bee.name = "Hutch"
bee.save # POST request (creates new record)

bee.name = "ハッチ"
bee.save # PATCH request (updates existing record)

bee.reload # GET request

bee.destroy # DELETE request

bee = Honeybee.find(9) # GET request
```

It's recommended that you read Spyke's documentation for more information on
these basic features. If you've used ActiveRecord or similar ORM libraries
you'll find it quite familiar.

Notice that `FmRest::Layout` is aliased as `FmRest::Spyke::Base`. Previous
versions of fmrest-ruby only provided the latter version, so if you're already
using `FmRest::Spyke::Base` there's no need to rename your classes to
`FmRest::Layout`, both will continue to work interchangeably.

In addition, `FmRest::Layout` extends `Spyke::Base` with the following
features:

### FmRest::Layout.fmrest_config=

This allows you to set Data API connection settings specific to your model
class:

```ruby
class Honeybee < FmRest::Layout
  self.fmrest_config = {
    host:     "…",
    database: "…",
    username: "…",
    password: "…"
  }
end
```

These settings are class-inheritable, so you could create a base class that
does the initial connection setup and then inherit from it in models using that
same connection. E.g.:

```ruby
class ApplicationFmLayout < FmRest::Layout
  self.fmrest_config = { host: "…", database: "…", … }
end

class Honeybee < ApplicationFmLayout
  # This model will use the same connection as ApplicationFmLayout
end
```

If `fmrest_config` is not set, your model will try to use
`FmRest.default_connection_settings` instead.

#### Connection settings overlays

There may be cases where you want to use a different set of connection settings
depending on context. For example, if you want to use username and password
provided by the user in a web application. Since `.fmrest_config` is set at the
class level, changing the username/password for the model in one context would
also change it in all other contexts, leading to security issues.

To solve this scenario, fmrest-ruby provides a way of defining thread-local,
reversible connection settings overlays through `.fmrest_config_overlay=`.

See the [main document on connection setting overlays](docs/ConfigOverlays.md)
for details on how it works.

### FmRest::Layout.layout

Use `layout` to set the layout name for your model.

```ruby
class Honeybee < FmRest::Layout
  layout "Honeybees Web"
end
```

Alternatively, if you're inheriting from `FmRest::Layout` directly you can set
the layout name in the class definition line:

```ruby
class Honeybee < FmRest::Layout("Honeybees Web")
```

Note that you only need to manually set the layout name if the name of the
class and the name of the layout differ, otherwise fmrest-ruby will just use
the name of the class.

### FmRest::Layout.request_auth_token

Requests a Data API session token using the connection settings in
`fmrest_config` and returns it if successful, otherwise returns `false`.

You normally don't need to use this method as fmrest-ruby will automatically
request and store session tokens for you (provided that `:autologin` is
`true` in the connection settings, which it is by default).

### FmRest::Layout.logout

Use `.logout` to log out from the database session (you may call it on any
model that uses the database session you want to log out from).

```ruby
Honeybee.logout
```

### Mapped FmRest::Layout.attributes

Spyke allows you to define your model's attributes using `attributes`, however
sometimes FileMaker's field names aren't very Ruby-ORM-friendly, especially
since they may sometimes contain spaces and other special characters, so
fmrest-ruby extends `attributes`' functionality to allow you to map
Ruby-friendly attribute names to FileMaker field names. E.g.:

```ruby
class Honeybee < FmRest::Layout
  attributes first_name: "First Name", last_name: "Last Name"
end
```

You can then simply use the pretty attribute names whenever working with your
model and they will get mapped to their FileMaker fields:

```ruby
bee = Honeybee.find(1)

bee.first_name # => "Princess"
bee.last_name  # => "Buzz"

bee.first_name = "Queen"

bee.attributes # => { "First Name": "Queen", "Last Name": "Buzz" }
```

### FmRest::Layout.has_portal

You can define portal associations on your model wth `has_portal`, as such:

```ruby
class Honeybee < FmRest::Layout
  has_portal :flowers
end

class Flower < FmRest::Layout
  attributes :color, :species
end
```

See the [main document on portal associations](docs/Portals.md) for details.

### Dirty attributes

fmrest-ruby includes support for ActiveModel's Dirty mixin out of the box,
providing methods like:

```ruby
bee = Honeybee.new

bee.changed? # => false

bee.name = "Maya"

bee.changed? # => true

bee.name_changed? # => true
```

fmrest-ruby uses the Dirty functionality to only send changed attributes back
to the server on save.

You can read more about [ActiveModel's Dirty in Rails
Guides](https://guides.rubyonrails.org/active_model_basics.html#dirty).

### Query API

Since Spyke is API-agnostic it only provides a wide-purpose `.where` method for
passing arbitrary parameters to the REST backend. fmrest-ruby however is well
aware of its backend API, so it extends Spkye models with a bunch of useful
querying methods: `.query`, `.match`, `.omit`, `.limit`, `.offset`, `.sort`,
`.portal`, `.script`, etc.

See the [main document on querying](docs/Querying.md) for detailed information
on the query API methods.

### Finding records in batches

Sometimes you want to iterate over a very large number of records to do some
processing, but requesting them all at once would result in one huge request to
the Data API, and loading too many records in memory all at once.

To mitigate this problem you can use `.find_in_batches` and `.find_each`.

See the [main document on finding in batches](docs/FindInBatches.md) for
detailed information on how those work.

### Container fields

You can define container fields on your model class with `container`:

```ruby
class Honeybee < FmRest::Layout
  container :photo, field_name: "Beehive Photo ID"
end
```

See the [main document on container fields](docs/ContainerFields.md) for
details on how to use it.

### Script execution

The FM Data API allows running scripts as part of many types of requests, and
`fmrest-spyke` provides mechanisms for all of them.

See the [main document on script execution](docs/ScriptExecution.md) for
details.

### Setting global field values

You can call `.set_globals` on any `FmRest::Layout` model to set global
field values on the database that model is configured for.

See the [main document on setting global field values](docs/GlobalFields.md)
for details.

### Rescuable mixin

Sometimes you may want to handle Data API errors at the model level. For such
cases fmrest-ruby provides an off-by-default mixin called `Rescuable` that
provides convenience macros for that. If you've used Ruby on Rails you may be
familiar with its syntax from controllers. E.g.

```ruby
class BeeBase < FmRest::Layout
  include FmRest::Spyke::Model::Rescuable

  rescue_from FmRest::APIError::SystemError, with: :notify_admin_of_system_error

  def self.notify_admin_of_system_error(e)
    # Shoot an email to the FM admin...
  end
end
```

Since `Rescuable` uses `ActiveSupport::Rescuable` internally, you may want to
check [Rails'
documentation](https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html)
too for details on how it works.

One caveat of using `rescue_from` is that it always catches exceptions at the
class level, so if you pass a method name to `with:` that method has to be a
class method. Also note that this will only catch exceptions raised during an
API call to the Data API server (in other words, only on actions that perform
an HTTP request).

## Logging

If using `fmrest-spyke` with Rails then pretty log output will be set up for
you automatically by Spyke (see [their
README](https://github.com/balvig/spyke#log-output)).

You can also enable simple Faraday logging of raw requests (useful for
debugging) by passing `log: true` in the options hash for either
`FmRest.default_connection_settings=` or your models' `fmrest_config=`, e.g.:

```ruby
FmRest.default_connection_settings = {
  host: "…",
  …
  log:  true
}

# Or in your model
class LoggyBee < FmRest::Layout
  self.fmrest_config = {
    host: "…",
    …
    log:  true
  }
end
```

You can also pass `log_level` to connection settings to change the severity of
log output (defaults to `:debug`).

By default fmrest-ruby logs to STDOUT or to Rails' logger object if available.
You can change this by providing your own logger object to `FmRest.logger=`:

```ruby
FmRest.logger = Logger.new("fmrest.log")
```

If you need to set up more complex logging for your models you can use the
`faraday` block inside your class to inject your own logger middleware into the
Faraday connection, e.g.:

```ruby
class LoggyBee < FmRest::Layout
  faraday do |conn|
    conn.response :logger, MyApp.logger, bodies: true
  end
end
```

## Gotchas

Read about unexpected scenarios in the [gotchas doc](docs/Gotchas.md).

## API implementation completeness table

FM Data API reference: https://help.claris.com/en/data-api-guide/

| FM 19 Data API feature              | Supported by basic connection | Supported by FmRest::Layout |
|-------------------------------------|-------------------------------|-----------------------------|
| Log in using HTTP Basic Auth        | Yes                           | Yes                         |
| Log in using OAuth                  | No                            | No                          |
| Log in to an external data source   | No                            | No                          |
| Log in using Claris ID account (FileMaker Cloud) | Yes              | Yes                         |
| Log out                             | Yes                           | Yes                         |
| Get product information             | Manual*                       | No                          |
| Get database names                  | Manual*                       | No                          |
| Get script names                    | Manual*                       | No                          |
| Get layout names                    | Manual*                       | No                          |
| Get layout metadata                 | Manual*                       | No                          |
| Create a record                     | Manual*                       | Yes                         |
| Edit a record                       | Manual*                       | Yes                         |
| Duplicate a record                  | Manual*                       | No                          |
| Delete a record                     | Manual*                       | Yes                         |
| Edit portal records                 | Manual*                       | Yes                         |
| Get a single record                 | Manual*                       | Yes                         |
| Get a range of records              | Manual*                       | Yes                         |
| Get container data                  | Manual*                       | Yes                         |
| Upload container data               | Manual*                       | Yes                         |
| Perform a find request              | Manual*                       | Yes                         |
| Set global field values             | Manual*                       | Yes                         |
| Run a script                        | Manual*                       | Yes                         |
| Run a script with another request   | Manual*                       | Yes                         |

\* You can manually supply the URL and JSON to a `FmRest` connection.

## Supported Ruby versions

fmrest-ruby aims to support and is [tested against](https://github.com/beezwax/fmrest-ruby/actions?query=workflow%3ACI)
the following Ruby implementations:

* Ruby 2.5
* Ruby 2.6
* Ruby 2.7
* Ruby 3.0

## Gem development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bundle exec rspec` to run the specs. You can also run `bin/console` for an
interactive prompt that will allow you to experiment (it will auto-load all
fixtures in spec/fixtures).

To install all gems onto your local machine, run
`bundle exec rake all:install`. To release a new version, update the version
number in `lib/fmrest/version.rb`, and then run `bundle exec rake all:release`,
which will create a git tag for the version, push git commits and tags, and
push the `.gem` files to [rubygems.org](https://rubygems.org).

## Disclaimer

This project is not sponsored by or otherwise affiliated with Claris
International Inc., an Apple Inc. subsidiary. FileMaker is a trademark of
Claris International Inc., registered in the U.S. and other countries.
