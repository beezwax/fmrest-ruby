# fmrest-ruby

<a href="https://rubygems.org/gems/fmrest"><img src="https://badge.fury.io/rb/fmrest.svg?style=flat" alt="Gem Version"></a>

A Ruby client for
[FileMaker 17's Data API](https://fmhelp.filemaker.com/docs/17/en/dataapi/)
using
[Faraday](https://github.com/lostisland/faraday) and with optional
[Spyke](https://github.com/balvig/spyke) support (ActiveRecord-ish models).

FileMaker 16's Data API is not supported (but you shouldn't be using it
anyway).

If you're looking for a Ruby client for the legacy XML/Custom Web Publishing
API try the fabulous [ginjo-rfm gem](https://github.com/ginjo/rfm) instead.

fmrest-ruby does not currently implement the full spec of FileMaker 17's Data
API.

## Installation

Add this line to your Gemfile:

```ruby
gem 'fmrest'

# Optional (for ORM features)
gem 'spyke'
```

## Basic usage

To get a Faraday connection that can handle FM's Data API auth workflow:

```ruby
connection = FmRest::V1.build_connection(
  host:     "example.com",
  database: "database name",
  username: "username",
  password: "password"
)
```

The returned connection will prefix any non-absolute paths with
`"/fmi/data/v1/databases/:database/"`, so you only need to supply the
meaningful part of the path.

To send a request to the Data API use Faraday's standard methods, e.g.:

```ruby
# Get all records
connection.get("layouts/MyFancyLayout/records")

# Create new record
connection.post do |req|
  req.url "layouts/MyFancyLayout/records"

  # You can just pass a hash for the JSON body
  req.body = { ... }
end
```

For each request fmrest-ruby will first request a session token (using the
provided username and password) if it doesn't yet have one in store.

## Connection settings

In addition to the required `:host`, `:database`, `:username` and `:password`
connection options, you can also pass `:ssl` and `:proxy`, which are passed to
the underlying [Faraday](https://github.com/lostisland/faraday) connection.

You can use this to, for instance, disable SSL verification:

```ruby
FmRest::V1.build_connection(
  host:     "example.com",
  ...
  ssl:      { verify: false }
)
```

You can use the `:log` option for basic request logging, see the section on
[Logging](#Logging) below.

### Default connection settings

If you're only connecting to a single FM database you can configure it globally
through `FmRest.default_connection_settings=`. E.g.:

```ruby
FmRest.default_connection_settings = {
  host:     "example.com",
  database: "database name",
  username: "username",
  password: "password"
}
```

This configuration will be used by default by `FmRest::V1.build_connection` as
well as your models whenever you don't pass a configuration hash explicitly.

## Session token store

By default fmrest-ruby will use a memory-based store for the session tokens.
This is generally good enough for development, but not good enough for
production, as in-memory tokens aren't shared across threads/processes.

Besides the default token store the following token stores are bundled with fmrest-ruby:

### ActiveRecord

On Rails apps already using ActiveRecord setting up this token store should be
dead simple:

```ruby
# config/initializers/fmrest.rb
require "fmrest/token_store/active_record"

FmRest.token_store = FmRest::TokenStore::ActiveRecord
```

No migrations are needed, the token store table will be created automatically
when needed, defaulting to the table name "fmrest_session_tokens". If you want
to change the table name you can do so by initializing the token store and
passing it the `:table_name` option:

```ruby
FmRest.token_store = FmRest::TokenStore::ActiveRecord.new(table_name: "my_token_store")
```

### Redis

To use the Redis token store do:

```ruby
require "fmrest/token_store/redis"

FmRest.token_store = FmRest::TokenStore::Redis
```

You can also initialize it with the following options:

* `:redis` - A `Redis` object to use as connection, if ommited a new `Redis`
  object will be created with remaining options
* `:prefix` - The prefix to use for token keys, by default `"fmrest-token:"`
* Any other options will be passed to `Redis.new` if `:redis` isn't provided

Examples:

```ruby
# Passing a Redis connection explicitly
FmRest.token_store = FmRest::TokenStore::Redis.new(redis: Redis.new, prefix: "my-fancy-prefix:")

# Passing options for Redis.new
FmRest.token_store = FmRest::TokenStore::Redis.new(prefix: "my-fancy-prefix:", host: "10.0.1.1", port: 6380, db: 15)
```

**NOTE:** redis-rb is not included as a gem dependency of fmrest-ruby, so you'll
have to add it to your Gemfile.

### Moneta

[Moneta](https://github.com/moneta-rb/moneta) is a key/value store wrapper
around many different storage backends. If ActiveRecord or Redis don't suit
your needs, chances are Moneta will.

To use it:

```ruby
# config/initializers/fmrest.rb
require "fmrest/token_store/moneta"

FmRest.token_store = FmRest::TokenStore::Moneta
```

By default the `:Memory` moneta backend will be used.

You can also initialize it with the following options:

* `:backend` - The moneta backend to initialize the store with
* `:prefix` - The prefix to use for token keys, by default `"fmrest-token:"`
* Any other options will be passed to `Moneta.new`

Examples:

```ruby
# Using YAML as a backend with a custom prefix
FmRest.token_store = FmRest::TokenStore::Moneta.new(
  backend: :YAML,
  file:    "tmp/tokens.yml",
  prefix:  "my-tokens"
)
```

**NOTE:** the moneta gem is not included as a dependency of fmrest-ruby, so
you'll have to add it to your Gemfile.

## Spyke support (ActiveRecord-like ORM)

[Spyke](https://github.com/balvig/spyke) is an ActiveRecord-like gem for
building REST models. fmrest-ruby has Spyke support out of the box, although
Spyke itself is not a dependency of fmrest-ruby, so you'll need to add it to
your Gemfile yourself:

```ruby
gem 'spyke'
```

Then require fmrest-ruby's Spyke support:

```ruby
# Put this in config/initializers/fmrest.rb if it's a Rails project
require "fmrest/spyke"
```

And finally extend your Spyke models with `FmRest::Spyke`:

```ruby
class Honeybee < Spyke::Base
  include FmRest::Spyke
end
```

This will make your Spyke model send all its requests in Data API format, with
token session auth. Find, create, update and destroy actions should all work
as expected.

Alternatively you can inherit directly from the shorthand
`FmRest::Spyke::Base`, which is in itself a subclass of `Spyke::Base` with
`FmRest::Spyke` already included:

```ruby
class Honeybee < FmRest::Spyke::Base
end
```

In this case you can pass the `fmrest_config` hash as an argument to `Base()`:

```ruby
class Honeybee < FmRest::Spyke::Base(host: "...", database: "...", username: "...", password: "...")
end

Honeybee.fmrest_config # => { host: "...", database: "...", username: "...", password: "..." }
```

All of Spyke's basic ORM operations work:

```ruby
bee = Honeybee.new

bee.name = "Hutch"
bee.save # POST request

bee.name = "ハッチ"
bee.save # PATCH request

bee.reload # GET request

bee.destroy # DELETE request

bee = Honeybee.find(9) # GET request
```

Read Spyke's documentation for more information on these basic features.

In addition `FmRest::Spyke` extends `Spyke::Base` subclasses with the following
features:

### Model.fmrest_config=

Usually to tell a Spyke object to use a certain Faraday connection you'd use:

```ruby
class Honeybee < Spyke::Base
  self.connection = Faraday.new(...)
end
```

fmrest-ruby simplfies the process of setting up your Spyke model with a Faraday
connection by allowing you to just set your Data API connection settings:

```ruby
class Honeybee < Spyke::Base
  include FmRest::Spyke

  self.fmrest_config = {
    host:     "example.com",
    database: "My Database",
    username: "...",
    password: "..."
  }
end
```

This will automatically create a proper Faraday connection for those connection
settings.

Note that these settings are inheritable, so you could create a base class that
does the initial connection setup and then inherit from it in models using that
same connection. E.g.:

```ruby
class BeeBase < Spyke::Base
  include FmRest::Spyke

  self.fmrest_config = {
    host:     "example.com",
    database: "My Database",
    username: "...",
    password: "..."
  }
end

class Honeybee < BeeBase
  # This model will use the same connection as BeeBase
end
```

### Model.layout

Use `layout` to set the `:layout` part of API URLs, e.g.:

```ruby
class Honeybee < FmRest::Spyke::Base
  layout "Honeybees Web" # uri path will be "layouts/Honeybees%20Web/records(/:id)"
end
```

This is much preferred over using Spyke's `uri` to set custom URLs for your
Data API models.

Note that you only need to set this if the name of the model and the name of
the layout differ, otherwise the default will just work.

### Mapped Model.attributes

Spyke allows you to define your model's attributes using `attributes`, however
sometimes FileMaker's field names aren't very Ruby-ORM-friendly, especially
since they may sometimes contain spaces and other special characters, so
fmrest-ruby extends `attributes`' functionality to allow you to map
Ruby-friendly attribute names to FileMaker field names. E.g.:

```ruby
class Honeybee < FmRest::Spyke::Base
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

### Model.has_portal

You can define portal associations on your model as such:

```ruby
class Honeybee < FmRest::Spyke::Base
  has_portal :flowers
end

class Flower < FmRest::Spyke::Base
  attributes :color, :species
end
```

In this case fmrest-ruby will expect the portal table name and portal object
name to be both "flowers", i.e. the expected portal JSON portion should look
like this:

```json
...
"portalData": {
  "flowers": [
    {
      "flowers::color": "red",
      "flowers::species": "rose"
    }
  ]
}
```

If you need to specify different values for them you can do so with
`portal_key` for the portal table name, and `attribute_prefix` for the portal
object name, and `class_name`, e.g.:

```ruby
class Honeybee < FmRest::Spyke::Base
  has_portal :pollinated_flowers, portal_key: "Bee Flowers",
                                  attribute_prefix: "Flower",
                                  class_name: "Flower"
end
```

The above will use the `Flower` model class and expects the following portal JSON
portion:

```json
...
"portalData": {
  "Bee Flowers": [
    {
      "Flower::color": "white",
      "Flower::species": "rose"
    }
  ]
}
```

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
querying methods.

#### .limit

`.limit` sets the limit for get and find request:

```ruby
Honeybee.limit(10)
```

NOTE: You can also set a default limit value for a model class, see
[Other notes on querying](#other-notes-on-querying).


#### .offset

`.offset` sets the offset for get and find requests:

```ruby
Honeybee.offset(10)
```

#### .sort

`.sort` (or `.order`) sets sorting options for get and find requests:

```ruby
Honeybee.sort(:name, :age)
Honeybee.order(:name, :age) # alias method
```

You can set descending sort order by appending either `!` or `__desc` to a sort
attribute (defaults to ascending order):

```ruby
Honeybee.sort(:name, :age!)
Honeybee.sort(:name, :age__desc)
```

NOTE: You can also set default sort values for a model class, see
[Other notes on querying](#other-notes-on-querying).

#### .portal

`.portal` (aliased as `.includes` and `.portals`) sets which portals to fetch
(if any) for get and find requests (this recognizes portals defined with
`has_portal`):

```ruby
Honeybee.portal(:hives)   # include just the :hives portal
Honeybee.includes(:hives) # alias method
Honeybee.portals(:hives, :flowers) # alias for pluralization fundamentalists
```

Chaining calls to `.portal` will add portals to the existing included list:

```ruby
Honeybee.portal(:flowers).portal(:hives) # include both portals
```

If you want to disable portals for the scope call `.portal(false)`:

```ruby
Honeybee.portal(false) # disable portals for this scope
```

If you want to include all portals call `.portal(true)`:

```ruby
Honeybee.portal(true) # include all portals
```

For convenience you can also use `.with_all_portals` and `.without_portals`,
which behave just as calling `.portal(true)` and `portal(false)` respectively.

NOTE: By default all portals are included.

#### .query

`.query` sets query conditions for a find request (and supports attributes as
defined with `attributes`):

```ruby
Honeybee.query(name: "Hutch")
# JSON -> {"query": [{"Bee Name": "Hutch"}]}
```

Passing multiple attributes to `.query` will group them in the same JSON object:

```ruby
Honeybee.query(name: "Hutch", age: 4)
# JSON -> {"query": [{"Bee Name": "Hutch", "Bee Age": 4}]}
```

Calling `.query` multiple times or passing it multiple hashes creates separate
JSON objects (so you can define OR queries):

```ruby
Honeybee.query(name: "Hutch").query(name: "Maya")
Honeybee.query({ name: "Hutch" }, { name: "Maya" })
# JSON -> {"query": [{"Bee Name": "Hutch"}, {"Bee Name": "Maya"}]}
```

#### .omit

`.omit` works like `.query` but excludes matches:

```ruby
Honeybee.omit(name: "Hutch")
# JSON -> {"query": [{"Bee Name": "Hutch", "omit": "true"}]}
```

You can get the same effect by passing `omit: true` to `.query`:

```ruby
Honeybee.query(name: "Hutch", omit: true)
# JSON -> {"query": [{"Bee Name": "Hutch", "omit": "true"}]}
```

#### Other notes on querying

You can chain all query methods together:

```ruby
Honeybee.limit(10).offset(20).sort(:name, :age!).portal(:hives).query(name: "Hutch")
```

You can also set default values for limit and sort on the class:

```ruby
class Honeybee < FmRest::Spyke::Base
  self.default_limit = 1000
  self.default_sort = [:name, :age!]
end
```

Calling any `Enumerable` method on the resulting scope object will trigger a
server request, so you can treat the scope as a collection:

```ruby
Honeybee.limit(10).sort(:name).each { |bee| ... }
```

If you want to explicitly run the request instead you can use `.find_some` on
the scope object:

```ruby
Honeybee.limit(10).sort(:name).find_some # => [<Honeybee...>, ...]
```

If you want just a single result you can use `.find_one` instead (this will
force `.limit(1)`):

```ruby
Honeybee.query(name: "Hutch").find_one # => <Honeybee...>
```

NOTE: If you know the id of the record you should use `.find(id)` instead of
`.query(id: id).find_one` (so that the request is sent as `GET ../:layout/records/:id`
instead of `POST ../:layout/_find`).

```ruby
Honeybee.find(89) # => <Honeybee...>
```

### Container fields

You can define container fields on your model class with `container`:

```ruby
class Honeybee < FmRest::Spyke::Base
  container :photo, field_name: "Beehive Photo ID"
end
```

`:field_name` specifies the original field in the FM layout and is optional, if
not given it will default to the name of your attribute (just `:photo` in this
example).

(Note that you don't need to define container fields with `attributes` in
addition to the `container` definition.)

This will provide you with the following instance methods:

```ruby
bee = Honeybee.new

bee.photo.url # The URL of the container file on the FileMaker server

bee.photo.download # Download the contents of the container as an IO object

bee.photo.upload(filename_or_io) # Upload a file to the container
```

`upload` also accepts an options hash with the following options:

* `:repetition` - Sets the field repetition
* `:filename` - The filename to use when uploading (defaults to
  `filename_or_io.original_filename` if available)
* `:content_type` - The MIME content type to use (defaults to
  `application/octet-stream`)

## Logging

If using fmrest-ruby + Spyke in a Rails app pretty log output will be set up
for you automatically by Spyke (see [their
README](https://github.com/balvig/spyke#log-output)).

You can also enable simple STDOUT logging (useful for debugging) by passing
`log: true` in the options hash for either
`FmRest.default_connection_settings=` or your models' `fmrest_config=`, e.g.:

```ruby
FmRest.default_connection_settings = {
  host:     "example.com",
  database: "My Database",
  username: "z3r0c00l",
  password: "abc123",
  log:      true
}

# Or in your model
class LoggyBee < FmRest::Spyke::Base
  self.fmrest_config = {
    host:     "example.com",
    database: "My Database",
    username: "...",
    password: "...",
    log:      true
  }
end
```

If you need to set up more complex logging for your models can use the
`faraday` block inside your class to inject your own logger middleware into the
Faraday connection, e.g.:

```ruby
class LoggyBee < FmRest::Spyke::Base
  faraday do |conn|
    conn.response :logger, MyApp.logger, bodies: true
  end
end
```

## TODO

- [ ] Support for FM18 features
- [ ] Better/simpler-to-use core Ruby API
- [ ] Better API documentation and README
- [ ] Oauth support
- [ ] Support for portal limit and offset
- [x] More options for token storage
- [x] Support for container fields
- [x] Optional logging
- [x] FmRest::Spyke::Base class for single inheritance (as alternative for mixin)
- [x] Specs
- [x] Support for portal data

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment (it will auto-load all fixtures in
spec/fixtures).

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to
adhere to the [Contributor Covenant](http://contributor-covenant.org) code of
conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
See [LICENSE.txt](LICENSE.txt).

## Disclaimer

This project is not sponsored by or otherwise affiliated with FileMaker, Inc,
an Apple subsidiary. FileMaker is a trademark of FileMaker, Inc., registered in
the U.S. and other countries.

## Code of Conduct

Everyone interacting in the fmrest-ruby project’s codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of
conduct](CODE_OF_CONDUCT.md).
