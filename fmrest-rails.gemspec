# frozen_string_literal: true

require_relative "lib/fmrest/version"

Gem::Specification.new do |spec|
  spec.name          = "fmrest-rails"
  spec.version       = FmRest::VERSION
  spec.authors       = ["Pedro Carbajal"]
  spec.email         = ["pedro_c@beezwax.net"]

  spec.summary       = %q{Rails ties and generators for fmrest gem}
  spec.description   = %q{fmrest-rails provides Rails integration for the fmrest gem.}
  spec.homepage      = "https://github.com/beezwax/fmrest-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z .yardopts lib/generators/* lib/fmrest-rails.rb lib/fmrest/railtie.rb CHANGELOG.md LICENSE.txt README.md`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency "fmrest-core", "=#{FmRest::VERSION}"

  # NOTE: Add development deps to fmrest.gemspec
end
