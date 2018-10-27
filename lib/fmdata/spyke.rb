require "fmdata/spyke/json_parser"
require "fmdata/spyke/model"

module FmData
  module Spyke
    def self.included(base)
      base.include Model
    end
  end
end
