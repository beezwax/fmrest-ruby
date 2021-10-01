# frozen_string_literal: true

require_relative "lib/fmrest/version"

Gem::Specification.new do |spec|
  spec.name          = "fmrest-core"
  spec.version       = FmRest::VERSION
  spec.authors       = ["Pedro Carbajal"]
  spec.email         = ["pedro_c@beezwax.net"]

  spec.summary       = "FileMaker Data API client using Faraday, core library"
  spec.description   = "fmrest-core is a FileMaker Data API client built with Faraday. It handles authentication as well as providing many utilities for working with the Data API. An ORM library built on top of fmrest-core is also available."
  spec.homepage      = "https://github.com/beezwax/fmrest-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z .yardopts lib CHANGELOG.md LICENSE.txt README.md`.split("\x0").reject do |f|
    f.match(%r{^(?:lib/fmrest[/-](?:spyke|cloud))})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if File.exist?("UPGRADING_FMREST_CORE")
    spec.post_install_message = File.read("UPGRADING_FMREST_CORE")
  end

  spec.add_dependency "faraday", ">= 0.9.0", "< 2.0"
  spec.add_dependency "faraday_middleware", ">= 0.9.1", "< 2.0"

  # NOTE: Add development deps to fmrest.gemspec
end
