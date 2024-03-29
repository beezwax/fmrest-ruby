## Script execution

The Data API allows running scripts directly, or as part of other API calls
(e.g. when saving a record). `fmrest-spyke` provides mechanisms for all of
them.

### Direct script execution

You can use `FmRest::Layout.execute(script_name, param)` to execute a script
directly. This is a class method, so you must call it on your layout model
class (i.e. not an record instance). E.g.:

```ruby
response = MyLayout.execute("Uppercasing Script", "hello")

# The returned object contains information on the script execution
response.result   # => "HELLO"
response.error    # => "0"
response.success? # true
```

This will return a `ScriptResult` object containing `result` (in case the
script returns a value) and `error` (an error code, `"0"` for "no error").

Keep in mind that scripts accept only one parameter as a string. Read the
section on [#limitations](limitations) down below for ways to get around this.

### Executing a script as part of another API call

You can execute scripts as part of a query, or when saving/deleting/reloading a
record. This section shows how.

#### Script options object format

All other script-capable requests take one or more of three possible script
execution options: `script.prerequest`, `script.presort` and plain `script`
(which fmrest-ruby dubs `after` for convenience).

Because of that fmrest-ruby uses a common object format for specifying script options
across multiple methods. That object format is as follows:

```ruby
# Just a string means to execute that `after' script without a parameter
"My Script"

# A 2-elemnent array means [script name, script parameter]
["My Script", "parameter"]

# A hash with keys :prerequest, :presort and/or :after sets those scripts for
{
  prerequest: "My Prerequest Script",
  presort: "My Presort Script",
  after: "My Script"
}

# Using 2-element arrays as objects in the hash allows specifying parameters
{
  prerequest: ["My Prerequest Script", "parameter"],
  presort: ["My Presort Script", "parameter"],
  after: ["My Script", "parameter"]
}
```

#### Script execution on record save, destroy and reload

A record instance's `.save` and `.destroy` methods both accept a `script:`
option to which you can pass a script options object with
[the above format](#script-options-object-format):

```ruby
# Save the record and execute an `after' script called "My Script"
bee.save(script: "My Script")

# Same as above but with an added parameter
bee.save(script: ["My Script", "parameter"])

# Save the record and execute a presort script and an `after' script
bee.save(script: { presort: "My Presort Script", after: "My Script" })

# Destroy the record and execute a prerequest script with a parameter
bee.destroy(script: { prerequest: ["My Prerequest Script", "parameter"] })

# Reload the record and execute a prerequest script with a parameter
bee.reload(script: { prerequest: ["My Prerequest Script", "parameter"] })
```

#### Retrieving script execution results

Every time a request is ran on a model or record instance of a model, a
thread-local `.last_request_metadata` attribute is set on that model,
which is a hash containing the results of script executions, if any were
performed, among other metadata.

The results for `:after`, `:prerequest` and `:presort` scripts are stored
separately, under their matching key.

```ruby
bee.save(script: { presort: "My Presort Script", after: "My Script" })

Honeybee.last_request_metadata.script
# => { after: { result: "oh hi", error: "0" }, presort: { result: "lo", error: "0" } }
```

#### Executing scripts through query requests

As mentioned under the [Query API](#query-api) section, you can use the
`.script` query method to specify that you want scripts executed when a query
is performed on that scope.

`.script` takes the same options object specified [above](#script-options-object-format):

```ruby
# Find one Honeybee record executing a presort and after script
Honeybee.script(presort: ["My Presort Script", "parameter"], after: "My Script").first
```

The model class' `.last_request_metadata` will be set in case you need to get the result.

In the case of retrieving multiple results (i.e. via `.find_some`) the
resulting collection will have a `.metadata` attribute method containing the
same metadata hash with script execution results. Note that this does not apply
to retrieving single records, in that case you'll have to use
`.last_request_metadata`.

### Limitations

When executing a FileMaker script from the Data API you're only allowed one
parameter as a string. You can get around this limitation somehow by encoding
structured data as JSON and sending it in said parameter. FileMaker scripting
provides functions for parsing and handling JSON, so it should be easy to
decode.

E.g.

```ruby
MyLayout.execute("My Script", { product: "Bicycle", color: "Red" }.to_json)
```
