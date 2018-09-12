require "faraday"
require "faraday_middleware"

require "fmdata/version"
require "fmdata/fm16"
require "fmdata/fm17"

module FmData
  class << self
    attr_accessor :config
  end
end
