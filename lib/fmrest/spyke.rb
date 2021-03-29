# frozen_string_literal: true

require "spyke"
require "fmrest"
require "fmrest/spyke/spyke_formatter"
require "fmrest/spyke/model"
require "fmrest/spyke/base"

module FmRest
  module Spyke
    def self.included(base)
      base.include Model
    end
  end
end
