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
    f.match(%r{^(\.github|test|spec|features|bin)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if File.exist?('UPGRADING')
    spec.post_install_message = File.read("UPGRADING")
  end

  spec.add_dependency 'faraday', '>= 0.9.0', '< 2.0'
  spec.add_dependency 'faraday_middleware', '>= 0.9.1', '< 2.0'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "spyke", ">= 5.3.3"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "activerecord", ENV["ACTIVE_RECORD_VERSION"]

  sqlite3_version = if (4.2..5.2).include?(ENV["ACTIVE_RECORD_VERSION"].to_s.gsub(/[^\d.]/, "").to_f)
                      "~> 1.3.0"
                    else
                      "~> 1.4.0"
                    end

  spec.add_development_dependency "sqlite3", sqlite3_version
  spec.add_development_dependency "mock_redis"
  spec.add_development_dependency "moneta"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "yard-activesupport-concern"
end
