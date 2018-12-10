lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fmdata/version"

Gem::Specification.new do |spec|
  spec.name          = "fmdata"
  spec.version       = FmData::VERSION
  spec.authors       = ["Pedro Carbajal", "Hannah Yiu"]
  spec.email         = ["pedro_c@beezwax.net"]

  spec.summary       = %q{FileMaker Data API REST client using Faraday}
  spec.description   = %q{FileMaker Data API REST client using Faraday, with optional ActiveRecord-like ORM based on Spyke}
  spec.homepage      = "https://www.beezwax.net/"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

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
