# frozen_string_literal: true

require_relative "lib/fmrest/version"

Gem::Specification.new do |spec|
  spec.name          = "fmrest-cloud"
  spec.version       = FmRest::VERSION
  spec.authors       = ["Pedro Carbajal"]
  spec.email         = ["pedro_c@beezwax.net"]

  spec.summary       = %q{FileMaker Cloud support for fmrest gem}
  spec.description   = %q{fmrest-cloud adds FileMaker Cloud (Cognito auth) support to the fmrest gem.}
  spec.homepage      = "https://github.com/beezwax/fmrest-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z .yardopts lib/fmrest-cloud.rb lib/fmrest/cloud* CHANGELOG.md LICENSE.txt README.md`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency "fmrest-core", "=#{FmRest::VERSION}"
  spec.add_dependency "aws-cognito-srp", ">= 0.4.0"

  # NOTE: Add development deps to fmrest.gemspec
end
