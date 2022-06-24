## Token stores

The following token store adapters are bundled together with `fmrest-core`.

### Memory

This is the default token store. It uses a memory-based store for the session
tokens. This is generally good enough during development, but generally a bad
idea for production as in-memory tokens aren't shared across threads/processes.

```ruby
# config/initializers/fmrest.rb

FmRest.token_store = FmRest::TokenStore::Memory
```

### ActiveRecord

On Rails apps that already use ActiveRecord, setting up this token store should
be dead simple:

```ruby
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

To use the Redis token store add `gem "redis"` to your Gemfile, then do:

```ruby
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

### Moneta

[Moneta](https://github.com/moneta-rb/moneta) is a key/value store wrapper
around many different storage backends. If ActiveRecord or Redis don't suit
your needs, chances are Moneta will.

To use it add `gem "moneta"` to your Gemfile, then do:

```ruby
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
