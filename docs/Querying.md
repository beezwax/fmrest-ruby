## Querying

`fmrest-spyke` provides the following chainable querying methods.

### .query

`.query` sets query conditions for a find request (with awareness of attribute
mappings defined with `attributes` on your layout class).

String conditions are sent unchanged in the request, so you can use
[FileMaker find operators](https://help.claris.com/en/pro-help/content/finding-text.html):

```ruby
# Find records with names containing the word "Hutch"
Honeybee.query(name: "=Hutch")
# JSON -> {"query": [{"Bee Name": "=Hutch"}]}
```

You can also pass date/datetime, or range Ruby objects as condition values, and
they'll be converted into their matching FileMaker search strings:

```ruby
Honeybee.query(age: 18..))
# JSON -> {"query": [{"Bee DOB": ">=18"}]}

Honeybee.query(date_of_birth: Date.today))
# JSON -> {"query": [{"Bee DOB": "01/02/2021"}]}

Honeybee.query(date_of_birth: (Date.today-1..Date.today))
# JSON -> {"query": [{"Bee DOB": "01/01/2021..01/02/2021"}]}
```

Passing multiple attributes to `.query` in a single conditions hash will group
them in the same JSON object:

```ruby
Honeybee.query(name: "=Hutch", age: 18..)
# JSON -> {"query": [{"Bee Name": "=Hutch", "Bee Age": ">=18"}]}
```

Calling `.query` multiple times (through method chaining) will by default merge
the given conditions with the pre-existing ones (resulting in logical AND
search of the given conditions):

```ruby
Honeybee.query(name: "=Hutch").query(age: 20)
# JSON -> {"query": [{"Bee Name": "=Hutch", "Bee Age": 20}]}
```

NOTE: Prior to version 0.15.0, fmrest-ruby behaved differently in the above case,
defaulting to logical OR addition of conditions with subsequent chained calls.

You can also pass multiple condition hashes to `.query`, resulting in a logical
OR search:

```ruby
Honeybee.query({ name: "=Hutch" }, { name: "=Maya" })
# JSON -> {"query": [{"Bee Name": "Hutch"}, {"Bee Name": "Maya"}]}
```

Alternatively you can prefix `.or` to chained call to `.query` to specify that
you want conditions added as new condition hashes in the request (logical OR)
instead of merged with pre-existing conditions:

```ruby
Honeybee.query(name: "=Hutch").or.query(name: "=Maya")
# JSON -> {"query": [{"Bee Name": "Hutch"}, {"Bee Name": "Maya"}]}

# .or accepts conditions directly as a shorthand for .or.query
Honeybee.query(name: "=Hutch").or(name: "=Maya")
# JSON -> {"query": [{"Bee Name": "Hutch"}, {"Bee Name": "Maya"}]}
```

You can also query portal parameters using a nested hash (provided that you
defined your portal in your layout class):

```ruby
Honeybee.query(tasks: { urgency: "=Today" })
# JSON -> {"query": [{"Bee Tasks::Urgency": "=Today"}]}
```

Passing strings instead of symbols for keys allows you to pass literal field
names, useful if for some reason you haven't defined attributes or portals in
your layout class:

```ruby
Honeybee.query("Bee Age" => 4, "Bee Tasks::Urgency" => "=Today")
# JSON -> {"query": [{"Bee Age": 4, "Bee Tasks::Urgency": "=Today"}]}
```

Passing `nil` as a condition will search for an empty field:

```ruby
Honeybee.query(name: nil)
# JSON -> {"query": [{"Bee Name": "="}]}
```

Passing `omit: true` in a conditions hash will cause FileMaker to exclude
results matching that conditions hash (see also `.omit` below for a shorthand):

```ruby
Honeybee.query(name: "=Hutch", omit: true)
# JSON -> {"query": [{"Bee Name": "=Hutch", "omit": "true"}]}
```

See `.match` below for a convenience exact-match companion for `.query`.

### .omit

`.omit` works like `.query` but excludes matches by adding `"omit": "true"` to
the resulting JSON:

```ruby
Honeybee.omit(name: "Hutch")
# JSON -> {"query": [{"Bee Name": "Hutch", "omit": "true"}]}
```

You can get the same effect by passing `omit: true` to `.query`:

```ruby
Honeybee.query(name: "Hutch", omit: true)
# JSON -> {"query": [{"Bee Name": "Hutch", "omit": "true"}]}
```

### .match

Similar to `.query`, but sets exact string match conditions by prefixing `==`
to the given query values, and escaping any find operators through
`FmRest.e()`. This is useful if you want to find for instance an exact email
address:

```ruby
Honeybee.match(email: "hutch@thehive.bee")
# JSON -> {"query": [{"Bee Email": "==hutch\@thehive.bee"}]}
```

You can also combine `.or.match` the same way you can `.or.query` to add
new conditions through logical OR.

### .limit

`.limit` sets the limit for get and find request:

```ruby
Honeybee.limit(10)
```

NOTE: You can also set a default limit value for a model class, see
[other notes on querying](#other-notes-on-querying).

You can also use `.limit` to set limits on portals:

```ruby
Honeybee.limit(hives: 3, tasks: 2)
```

To remove the limit on a portal set it to `nil`:

```ruby
Honeybee.limit(tasks: nil)
```

### .offset

`.offset` sets the offset for get and find requests:

```ruby
Honeybee.offset(10)
```

You can also use `.offset` to set offsets on portals:

```ruby
Honeybee.offset(hives: 3, tasks: 2)
```

To remove the offset on a portal set it to `nil`:

```ruby
Honeybee.offset(tasks: nil)
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
Honeybee.portals(:hives, :tasks) # alias for pluralization fundamentalists
```

Chaining calls to `.portal` will add portals to the existing included list:

```ruby
Honeybee.portal(:tasks).portal(:hives) # include both portals
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
class Honeybee < FmRest::Layout
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

If you know the recordId of the record you should use `.find(id)` instead of
`.query(id: id).first` (this would actually not work since recordId is not a
queryable attribute).

```ruby
Honeybee.find(89) # => <Honeybee...>
```

Note also that if you use `.find(id)` your `.query()` parameters (as well as
limit, offset and sort parameters) will be discarded as they're not supported
by the single record Data API endpoint.

A `.first!` method also exists, which raises an exception if no records matched
your query. This is useful when using some form of unique identification other
than recordId. E.g.

```ruby
Honeybee.query(uuid: "BEE-2f37a290-f3ac-11ec-b939-0242ac120002").first!
```
