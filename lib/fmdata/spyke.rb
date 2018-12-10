require "fmdata/spyke/json_parser"
require "fmdata/spyke/model"
require "fmdata/spyke/base"

module FmData
  module Spyke
    def self.included(base)
      base.include Model
    end
  end
end
