# frozen_string_literal: true

require_relative "lib/fmrest/version"

Gem::Specification.new do |spec|
  spec.name          = "fmrest"
  spec.version       = FmRest::VERSION
  spec.authors       = ["Pedro Carbajal"]
  spec.email         = ["pedro_c@beezwax.net"]

  spec.summary       = %q{FileMaker Data API client}
  spec.description   = %q{fmrest is just a wrapper for two other gems: fmrest-core and fmrest-spyke.}
  spec.homepage      = "https://github.com/beezwax/fmrest-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z .yardopts CHANGELOG.md LICENSE.txt README.md`.split("\x0")

  if File.exist?("UPGRADING_FMREST")
    spec.post_install_message = File.read("UPGRADING_FMREST")
  end

  spec.add_dependency "fmrest-core", "=#{FmRest::VERSION}"
  spec.add_dependency "fmrest-spyke", "=#{FmRest::VERSION}"

  spec.add_development_dependency "bundler", "~> 2.2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "yard-activesupport-concern"

  ar_version      = ENV["ACTIVE_RECORD_VERSION"] || "~> 6.0"
  sqlite3_version = if (4.2..5.2).include?(ar_version.to_s.gsub(/[^\d.]/, "").to_f)
                      "~> 1.3.0"
                    else
                      "~> 1.4.0"
                    end

  spec.add_development_dependency "activerecord", ar_version
  spec.add_development_dependency "sqlite3", sqlite3_version
  spec.add_development_dependency "mock_redis"
  spec.add_development_dependency "moneta"
end
