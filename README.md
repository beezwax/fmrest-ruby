# FmData

A Ruby client for FileMaker 17's Data API using
[Faraday](https://github.com/lostisland/faraday) and with additional (optional)
[Spyke](https://github.com/balvig/spyke) support.

FileMaker 16's Data API is not supported (but you shouldn't be using it
anyway).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fmdata', git: 'https://gitlab.beezwax.net/pedro_c/fmdata'
```

And then execute:

    $ bundle

## Basic usage

To get a Faraday connection that can handle FM's Data API auth workflow:

```ruby
connection = FmData::V1.build_connection(
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

For each request FmData will first request a session token (using the provided
username and password) if it doesn't yet have one in store.

## Session token store

By default FmData will use a memory-based store for the session tokens. This is
generally good enough for development, but not good enough for production, as
in-memory tokens aren't shared across threads/processes.

Besides the default memory token store an ActiveRecord-based token store is
included with the gem (maybe more to come later).

On Rails apps already using ActiveRecord setting up this token store should be
dead simple:

```ruby
# config/initializers/fmdata.rb
require "fmdata/v1/token_store/active_record"

FmData.token_store = FmData::V1::TokenStore::ActiveRecord
```

No migrations are needed, the token store table will be created automatically
when needed, defaulting to the table name "fmdata_session_tokens".

## Spyke support

Spyke is an ActiveRecord-like gem for building REST models. FmData has Spyke
support out of the box, although Spyke itself is not a dependency of FmData, so
you'll need to install it yourself:

```ruby
gem 'spyke'
```

Then require FmData's Spyke support:

```ruby
# config/initializers/fmdata.rb
require "fmdata/spyke"
```

And finally extend your Spyke models with `FmData::Spyke`:

```ruby
class Kitty < Spyke::Base
  include FmData::Spyke
end
```

This will make your Spyke model send all its requests in Data API format, with
token session auth. Find, create, update and destroy actions should all work
as expected.

Additionally this extends `Spyke::Base` subclasses with the following features:

### Model.fmdata_config=

Usually to tell a Spyke object to use a certain Faraday connection you'd use:

```ruby
class Kitty < Spyke::Base
  self.connection = Faraday.new(...)
end
```

FmData simplfies the process of setting up your Spyke model with a Faraday
connection by allowing you to just set your Data API connection settings:

```ruby
class Kitty < Spyke::Base
  include FmData::Spyke

  self.fmdata_config = {
    host:     "example.com",
    database: "database name",
    username: "username",
    password: "password"
  }
end
```

This will automatically create a proper Faraday connection for those connection
settings.

Note that these settings are inheritable, so you could create a base class that
does the initial connection setup and then inherit from it in models using that
same connection. E.g.:

```ruby
class KittyDbModel < Spyke::Base
  include FmData::Spyke

  self.fmdata_config = {
    host:     "example.com",
    database: "database name",
    username: "username",
    password: "password"
  }
end

class Kitty < KittyDbModel
  # This will use the same connection as KittyDbModel
end
```

### Model.layout

Use `layout` to set the `:layout` part of API URLs, e.g.:

```ruby
class Kitty
  include FmData::Spyke

  layout "FluffyKitty" # uri path will be layouts/FluffyKitty/records(/:id)
end
```

This is much preferred over using Spyke's `uri` to set custom URLs for your
Data API models.

Note that you only need to set this if the name of the model and the name of
the layout differ, otherwise the default will just work.

### Mapped Model.attributes

Spyke allows you to define your model's attributes using `attributes`, however
sometimes FileMaker's field names aren't very Ruby-ORM-friendly, especially
since they may sometimes contain spaces and other special characters, so FmData
extends `attributes`' functionality to allow you to map Ruby-friendly attribute
names to FileMaker field names. E.g.:

```ruby
class Kitty
  include FmData::Spyke

  attributes first_name: "First Name", last_name: "Last Name"
end
```

You can then simply use the pretty attribute names whenever working with your
model and they will get mapped to their FileMaker fields:

```ruby
kitty = Kitty.find(1)

kitty.first_name # => "Mr."
kitty.last_name  # => "Fluffers"

kitty.first_name = "Dr."

kitty.attributes # => { "First Name": "Dr.", "Last Name": "Fluffers" }
```

### Query API

Since Spyke is API-agnostic it only provides a wide-purpose `.where` method for
passing arbitrary parameters to the REST backend. FmData however is well aware
of its backend API, so it extends Spkye models with a bunch of useful querying
methods.

```ruby
class Kitty < Spyke::Base
  include FmData::Spyke

  attributes name: "CatName", age: "CatAge"

  has_portal :toys, portal_key: "CatToys"
end
```

`.limit` sets the limit for get and find request:

```ruby
Kitty.limit(10)
```

`.offset` sets the offset for get and find requests:

```ruby
Kitty.offset(10)
```

`.sort` (or `.order`) sets sorting options for get and find requests:

```ruby
Kitty.sort(:name, :age)
Kitty.order(:name, :age) # alias method
```

You can set descending sort order by appending either `!` or `__desc` to a sort
attribute (defaults to ascending order):

```ruby
Kitty.sort(:name, :age!)
Kitty.sort(:name, :age__desc)
```

`.portal` (or `.includes`) sets the portals to fetch for get and find requests
(this recognizes portals defined with `has_portal`):

```ruby
Kitty.portal(:toys)
Kitty.includes(:toys) # alias method
```

`.query` sets query conditions for a find request (and supports attributes as
defined with `attributes`):

```ruby
Kitty.query(name: "Mr. Fluffers")
# JSON -> {"query": [{"CatName": "Mr. Fluffers"}]}
```

Passing multiple attributes to `.query` will group them in the same JSON object:

```ruby
Kitty.query(name: "Mr. Fluffers", age: 4)
# JSON -> {"query": [{"CatName": "Foo", "CatAge": 22}]}
```

Calling `.query` multiple times or passing it multiple hashes creates separate
JSON objects (so you can define OR queries):

```ruby
Kitty.query(name: "Mr. Fluffers").query(name: "Coronel Chai Latte")
Kitty.query({ name: "Mr. Fluffers" }, { name: "Coronel Chai Latte" })
# JSON -> {"query": [{"CatName": "Mr. Fluffers"}, {"CatName": "Coronel Chai Latte"}]}
```

`.omit` works like `.query` but excludes matches:

```ruby
Kitty.omit(name: "Captain Whiskers")
# JSON -> {"query": [{"CatName": "Captain Whiskers", "omit": "true"}]}
```

You can chain all query methods together:

```ruby
Kitty.limit(10).offset(20).sort(:name, :age!).portal(:toys).query(name: "Mr. Fluffers")
```

You can also set default values for limit and sort on the class:

```ruby
Kitty.default_limit = 1000
Kitty.default_sort = [:name, :age!]
```

Calling any `Enumerable` method on the resulting scope object will trigger a
server request, so you can treat the scope as a collection:

```ruby
Kitty.limit(10).sort(:name).each { |kitty| ... }
```

If you want to explicitly run the request instead you can use `.find_some` on
the scope object:

```ruby
Kitty.limit(10).sort(:name).find_some # => [<Kitty...>, ...]
```

If you want just a single result you can use `.find_one` instead (this will
force `.limit(1)`):

```ruby
Kitty.query(name: "Mr. Fluffers").find_one # => <Kitty...>
```

NOTE: If you know the id of the record you should use `.find(id)` instead of
`.query(id: id).find_one` (so that the request is sent as `GET ../:layout/records/:id`
instead of `POST ../:layout/_find`).

```ruby
Kitty.find(89) # => <Kitty...>
```

## TODO

- [ ] Better/simpler-to-use core Ruby API
- [ ] Better API documentation and README
- [ ] FmData::Spyke::Base class for single inheritance (as alternative for mixin)
- [ ] Oauth support
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

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the FmData project’s codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of
conduct](CODE_OF_CONDUCT.md).
