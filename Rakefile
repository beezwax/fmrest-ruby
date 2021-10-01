# frozen_string_literal: true

require "bundler/gem_helper"
require "rspec/core/rake_task"

gems = Dir[File.join(__dir__, "*.gemspec")].map { |f| File.basename(f, ".gemspec") }

gems.each do |gem|
  namespace gem do
    Bundler::GemHelper.install_tasks(name: gem)
  end
end

namespace :all do
  %w[build install install:local release].each do |t|
    desc "Run `#{t}` for all gems"
    task t => gems.map {|gem| "#{gem}:#{t}" }
  end
end

RSpec::Core::RakeTask.new(:spec)
task default: :spec
