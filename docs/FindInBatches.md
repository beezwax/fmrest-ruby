## Finding records in batches

Sometimes you want to iterate over a very large number of records to do some
processing, but requesting them all at once would result in one huge request to
the Data API and loading too many records in memory all at once.

To mitigate this problem you can use `.find_in_batches` and `.find_each`.

If you've used ActiveRecord you may be familiar with how they operate:

```ruby
# Find records in batches of 100 each
Honeybee.query(hive: "Queensville").find_in_batches(batch_size: 100) do |batch|
  dispatch_bees(batch)
end

# Iterate over all records using batches
Honeybee.query(hive: "Queensville").find_each(batch_size: 100) do |bee|
  bee.dispatch
end
```

`.find_in_batches` yields collections of records (batches), while `.find_each`
yields individual records, but using batches behind the scenes.

Both methods accept a block-less form in which case they return an
`Enumerator`:

```ruby
batch_enum = Honeybee.find_in_batches

batch = batch_enum.next # => Spyke::Collection

batch_enum.each do |batch|
  process_batch(batch)
end

record_enum = Honeybee.find_each

record_enum.next # => Honeybee
```

NOTE: By its nature, batch processing is subject to race conditions if other
processes are modifying the database.

