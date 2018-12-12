lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fmrest/version"

Gem::Specification.new do |spec|
  spec.name          = "fmrest"
  spec.version       = FmRest::VERSION
  spec.authors       = ["Pedro Carbajal"]
  spec.email         = ["pedro_c@beezwax.net"]

  spec.summary       = %q{FileMaker Data API client using Faraday}
  spec.description   = %q{FileMaker Data API client using Faraday, with optional ActiveRecord-like ORM based on Spyke}
  spec.homepage      = "https://github.com/beezwax/fmrest-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|bin)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'faraday', '>= 0.9.0', '< 2.0'
  spec.add_dependency 'faraday_middleware', '>= 0.9.1', '< 2.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "spyke"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "multi_json"
  spec.add_development_dependency "pry-byebug"
end
