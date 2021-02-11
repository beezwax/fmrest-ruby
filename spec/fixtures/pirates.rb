# frozen_string_literal: true

require_relative "base"

class Pirate < FixtureBase
  layout :Pirates

  attributes :name, :rank

  container :photo, field_name: "Photo"
end

class Cabin < FixtureBase; end

class Ship < FixtureBase
  layout :Ships

  attributes :name

  has_portal :crew, portal_key: "PiratesTable", attribute_prefix: "Pirate", class_name: "Pirate"

  has_portal :cabins, class_name: "Cabin"
end
