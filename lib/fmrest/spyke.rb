# frozen_string_literal: true

begin
  require "spyke"
rescue LoadError => e
  e.message << " (Did you include Spyke in your Gemfile?)" unless e.message.frozen?
  raise e
end

require "fmrest"
require "fmrest/spyke/json_parser"
require "fmrest/spyke/model"
require "fmrest/spyke/base"

module FmRest
  module Spyke
    def self.included(base)
      base.include Model
    end
  end
end
