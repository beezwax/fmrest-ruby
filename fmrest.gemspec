# frozen_string_literal: true

require_relative "lib/fmrest/version"

Gem::Specification.new do |spec|
  spec.name          = "fmrest"
  spec.version       = FmRest::VERSION
  spec.authors       = ["Pedro Carbajal"]
  spec.email         = ["pedro_c@beezwax.net"]

  spec.summary       = %q{FileMaker Data API client}
  spec.description   = %q{FileMaker Data API client with ORM features. This gem is a wrapper for other gems: fmrest-core, fmrest-spyke and fmrest-rails.}
  spec.homepage      = "https://github.com/beezwax/fmrest-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z .yardopts CHANGELOG.md LICENSE.txt README.md`.split("\x0")

  if File.exist?("UPGRADING_FMREST")
    spec.post_install_message = File.read("UPGRADING_FMREST")
  end

  spec.add_dependency "fmrest-core", "=#{FmRest::VERSION}"
  spec.add_dependency "fmrest-spyke", "=#{FmRest::VERSION}"
  spec.add_dependency "fmrest-rails", "=#{FmRest::VERSION}"

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rexml" # See https://bugs.ruby-lang.org/issues/16485
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "yard-activesupport-concern"

  ar_version = ENV["ACTIVE_RECORD_VERSION"] || ">= 7.1"
  sqlite3_version =
    case ar_version.to_s.gsub(/[^\d.]/, "").to_f
    when 4.2..5.2
      "~> 1.3.0"
    when 6.0..7.0
      "~> 1.4.0"
    when 7.1..7.2
      ">= 1.4.0"
    else
      ">= 2.1"
    end

  spec.add_development_dependency "activerecord", ar_version
  spec.add_development_dependency "sqlite3", sqlite3_version
  spec.add_development_dependency "mock_redis"
  spec.add_development_dependency "moneta"
end
