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
generally good enough for development, but not good enough for production, as in-memory
tokens aren't shared across threads/processes.

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

And finally extend your Spyke models with `FmData::Spyke::Model`:

```ruby
class Kitty
  include FmData::Spyke::Model
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

FmData simplfiies the process of setting up your Spyke model with a Farday
connection by allowing you to just set your Data API connection settings:

```ruby
class Kitty < Spyke::Base
  include FmData::Spyke::Model

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
  include FmData::Spyke::Model

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
  include FmData::Spyke::Model

  layout "FluffyKitty" # API path will begin with layouts/FluffyKitty/records
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
  include FmData::Spyke::Model

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

## TODO

[ ] Specs
[ ] Support for portal data
[ ] Better/simpler-to-use core Ruby API
[ ] Oauth support

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/fmdata. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fmdata project’s codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/[USERNAME]/fmdata/blob/master/CODE_OF_CONDUCT.md).
