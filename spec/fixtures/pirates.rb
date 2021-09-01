# frozen_string_literal: true

require_relative "base"

class Ship < FixtureBase
  layout :Ships

  attributes :name

  has_portal :crew, portal_key: "PiratesPortal",
                    attribute_prefix: "Pirate",
                    class_name: "Pirate"

  has_portal :cabins, class_name: "Cabin"
end

class Pirate < FixtureBase
  layout :Pirates

  attributes name: "Name",
             rank: "Rank",
             parrot_name: "Parrot::Name"

  container :photo, field_name: "Photo"
end

class Cabin < FixtureBase; end
