## Portal associations

`fmrest-spyke` allows you to define portal associations in your models.

### FmRest::Layout.has_portal

You can define portal associations on your model as such:

```ruby
class Honeybee < FmRest::Layout
  has_portal :flowers
end

class Flower < FmRest::Layout
  attributes :color, :species
end
```

In this case fmrest-ruby will expect the portal table name and portal object
name to be both "flowers", i.e. the expected portal portion of the Data API
JSON should look like this:

```json
…
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
class Honeybee < FmRest::Layout
  has_portal :pollinated_flowers, portal_key: "Bee Flowers",
                                  attribute_prefix: "Flower",
                                  class_name: "Flower"
end
```

The above will use the `Flower` model class and expects the following portal JSON
portion:

```json
…
"portalData": {
  "Bee Flowers": [
    {
      "Flower::color": "white",
      "Flower::species": "rose"
    }
  ]
}
```

Notice that despite using `FmRest::Layout` to define our portal models
(`Flower` in the example above), it is not required to have an actual matching
layout in FileMaker, as the data would be coming from the portal.

### Adding records to a portal

You can instantiate new records directly into a portal with
`.portal_name.build`, e.g.:

```ruby
class Honeybee < FmRest::Layout
  has_portal :tasks
end

class Task < FmRest::Layout
end

honeybee = Honeybee.new

honeybee.tasks.build(description: "Collect pollen")
honeybee.tasks.build(description: "Sting farmer")

# Persist the parent record along with its portal records
honeybee.save
```

You can also add unpersisted record instances with `<<` (also aliased as
`.push` and `.concat`). This method also accepts arrays of records, and can be
chained.  e.g.:

```ruby
honeybee.missions << Task.new

# Passing an array of records
honeybee.missions << [Task.new, Task.new]

# Chaining
honeybee.missions << Task.new << Task.new
```

Note that even though `fmrest-spyke` will allow you to add persisted records to
the association through `<<`, far as we're aware the Data API doesn't support
adding existing pre-records to a portal, so saving the parent record in such a
case will have no effect.

### Deleting portal records

To delete portal records you first need to mark the records you want deleted
with `.mark_for_destruction`, and then save the parent record.

E.g.:

```ruby
class Honeybee < FmRest::Layout
  has_portal :flowers
end

honeybee = Honeybee.first

honeybee.flowers.count # => 4

# Mark first portal item for being deleted on next save
honeybee.flowers.first.mark_for_destruction

honeybee.save

honeybee.flowers.count # => 3
```

### Modifying portal records

Portal records that get loaded with their parent record can have their
attributes modified normally, and those changes will be sent along with the
parent's the next time `.save` is called on the parent. E.g.:

```ruby
honeybee = Honeybee.first

honeybee.flowers.first.name = "Daisy"

honeybee.save # Saves the changes to the flower
```

**There's a gotcha though:** since the DAPI doesn't include the new modIds for
the modified portal records in the save response, `fmrest-spyke` doesn't update
the `__mod_id` attributes on those records either. This means that if you want
to make changes to a portal record after you've already saved the parent,
you'll have to first reload the parent to refresh the modIds. E.g.:

```ruby
honeybee = Honeybee.first

honeybee.flowers.first.name = "Daisy"
honeybee.save # First save works

honeybee.flowers.first.name = "Lily"
honeybee.save # Will fail with a mismatch modId error

honeybee.reload # Reload the parent to refresh modIds
honeybee.flowers.first.name = "Lily"
honeybee.save # This will save
```

This, however, shouldn't be a problem for most web applications where you only
perform one save on the same record per request, reloading it from scratch each
time.
