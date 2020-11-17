## Setting global field values

You can call `.set_globals` on any `FmRest::Spyke::Base` model to set global
field values on the database that model is configured for.

You can pass it either a hash of fully qualified field names
(table_name::field_name), or 1-level-deep nested hashes, with the outer being a
table name and the inner keys being the field names:

```ruby
Honeybee.set_globals(
  "beeTable::myVar"      => "value",
  "beeTable::myOtherVar" => "also a value"
)

# Equivalent to the above example
Honeybee.set_globals(beeTable: { myVar: "value", myOtherVar: "also a value" })

# Combined
Honeybee.set_globals(
  "beeTable::myVar" => "value",
  beeTable: { myOtherVar: "also a value" }
)
```
