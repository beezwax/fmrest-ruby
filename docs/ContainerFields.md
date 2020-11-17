## Container fields

You can define container fields on your model class with `container`:

```ruby
class Honeybee < FmRest::Spyke::Base
  container :photo, field_name: "Beehive Photo ID"
  container :resume, field_name: "Resume"
end
```

`:field_name` specifies the original field in the FM layout and is optional, if
not given it will default to the name of your attribute (just `:photo` in this
example).

(Note that you don't need to define container fields with `attributes` in
addition to the `container` definition.)

This will provide you with the following instance methods:

```ruby
bee = Honeybee.new

bee.photo.url # The URL of the container file on the FileMaker server

bee.photo.download # Download the contents of the container as an IO object

bee.photo.upload(filename_or_io) # Upload a file to the container
```

`upload` also accepts an options hash with the following options:

* `:repetition` - Sets the field repetition
* `:filename` - The filename to use when uploading (defaults to
  `filename_or_io.original_filename` if available)
* `:content_type` - The MIME content type to use (defaults to
  `application/octet-stream`)
