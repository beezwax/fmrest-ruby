## Date fields

Since the Data API uses JSON (wich doesn't provide a native date/time object),
dates and timestamps are received in string format. By default fmrest-ruby
leaves those string fields untouched, but it provides an opt-in feature to try
to automatically "coerce" them into Ruby date objects.

The connection option `:coerce_dates` controls this feature. Possible values
are:

* `:full` - whenever a string matches the given date/timestamp/time format,
  convert them to `Date` or `DateTime` objects as appropriate
* `:hybrid` or `true` - similar as above, but instead of converting to regular
  `Date`/`DateTime` it converts strings to `FmRest::StringDate` and
  `FmRest::StringDateTime`, "hybrid" classes provided by fmrest-ruby that
  retain the functionality of `String` while also providing most the
  functionality of `Date`/`DateTime` (more on this below)
* `false` - disable date coercion entirely (default), leave original string
  values untouched

Enabling date coercion works with both basic fmrest-ruby connections and Spyke
models (ORM).

The connection options `:date_format`, `:timestamp_format` and `:time_format`
control how to match and parse dates. You only need to provide these if you use
a date/time localization different from American format (the default).

Future versions of fmrest-ruby will provide better (and less heuristic) ways of
specifying and/or detecting date fields (e.g. by requesting layout metadata or
a DSL in model classes).

### Hybrid string/date objects

`FmRest::StringDate` and `FmRest::StringDateTime` are special classes that
inherit from `String`, but internally parse and store a `Date` or `DateTime`,
and delegate any methods not provided by `String` to those objects. In other
words, they quack like a duck *and* bark like a dog.

You can use these when you want fmrest-ruby to provide you with date objects,
but you don't want to worry about date coercion of false positives (i.e. a
string field that gets converted to `Date` because it just so matched the given
date format).

Be warned however that these classes come with a fair share of known gotchas
(see GitHub wiki for more info). Some of those gothas can be removed by calling

```ruby
FmRest::StringDateAwareness.enable
```

Which will extend the core `Date` and `DateTime` classes to be aware of
`FmRest::StringDate`, especially when calling `Date.===`, `Date.parse` or
`Date._parse`.

If you're working with ActiveRecord models this will also make them accept
`FmRest::StringDate` values for date fields.

### Timezones

fmrest-ruby has basic timezone support. You can set the `:timezone` option in
your connection settings to one of the following values:

* `:local` - dates will be converted to your system local time offset (as
  defined by `ENV["TZ"]`), or the timezone set by `Time.zone` if you're using
  ActiveSupport
* `:utc` - dates will be converted to UTC offset
* `nil` - (default) ignore timezones altogether
