require_relative "base"

class Pirate < FixtureBase
  layout :Pirates

  attributes :name, :rank

  container :photo, field_name: "Photo"
end

class Ship < FixtureBase
  layout :Ships

  attributes :name

  has_portal :crew, portal_key: "PiratesTable", attribute_prefix: "Pirate", class_name: "Pirate"
end
