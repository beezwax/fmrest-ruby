require "spyke/fixtures/base"

class Pirate < FixtureBase
  layout :Pirates

  attributes :name, :rank
end

class Ship < FixtureBase
  layout :Ships

  attributes :name

  portal :crew, portal_key: "Pirates", class_name: "Pirate"
end
