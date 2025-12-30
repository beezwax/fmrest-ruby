# frozen_string_literal: true

require_relative "lib/fmrest/version"

Gem::Specification.new do |spec|
  spec.name          = "fmrest-spyke"
  spec.version       = FmRest::VERSION
  spec.authors       = ["Pedro Carbajal"]
  spec.email         = ["pedro_c@beezwax.net"]

  spec.summary       = %q{FileMaker Data API ORM client library}
  spec.description   = %q{fmrest-spyke is an ActiveRecord-like ORM client library for the FileMaker Data API built on top of fmrest-core and Spyke (https://github.com/balvig/spyke).}
  spec.homepage      = "https://github.com/beezwax/fmrest-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z .yardopts lib/fmrest-spyke.rb lib/fmrest/spyke* CHANGELOG.md LICENSE.txt README.md`.split("\x0")
  spec.require_paths = ["lib"]

  if File.exist?("UPGRADING_FMREST_SPYKE")
    spec.post_install_message = File.read("UPGRADING_FMREST_SPYKE")
  end

  spec.add_dependency "fmrest-core", "=#{FmRest::VERSION}"
  spec.add_dependency "spyke", ">= 7.0"
  spec.add_dependency "activesupport", ">= 5.2"
  spec.add_dependency "ostruct"

  # NOTE: Add development deps to fmrest.gemspec
end
