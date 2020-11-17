## Querying

`fmrest-spyke` provides the following chainable querying methods.

### .limit

`.limit` sets the limit for get and find request:

```ruby
Honeybee.limit(10)
```

NOTE: You can also set a default limit value for a model class, see
[other notes on querying](#other-notes-on-querying).

You can also use `.limit` to set limits on portals:

```ruby
Honeybee.limit(hives: 3, flowers: 2)
```

To remove the limit on a portal set it to `nil`:

```ruby
Honeybee.limit(flowers: nil)
```

### .offset

`.offset` sets the offset for get and find requests:

```ruby
Honeybee.offset(10)
```

You can also use `.offset` to set offsets on portals:

```ruby
Honeybee.offset(hives: 3, flowers: 2)
```

To remove the offset on a portal set it to `nil`:

```ruby
Honeybee.offset(flowers: nil)
```

### .sort

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

### .portal

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

### .query

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

### .omit

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

### .script

`.script` enables the execution of scripts during query requests.

```ruby
Honeybee.script("My script").find_some # Fetch records and execute a script
```

See section on [script execution](#script-execution) below for more info.

### Other notes on querying

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

If you want just a single result you can use `.first` instead (this will
force `.limit(1)`):

```ruby
Honeybee.query(name: "Hutch").first # => <Honeybee...>
```

If you know the id of the record you should use `.find(id)` instead of
`.query(id: id).first` (so that the sent request is
`GET ../:layout/records/:id` instead of `POST ../:layout/_find`).

```ruby
Honeybee.find(89) # => <Honeybee...>
```

Note also that if you use `.find(id)` your `.query()` parameters (as well as
limit, offset and sort parameters) will be discarded as they're not supported
by the single record Data API endpoint.
