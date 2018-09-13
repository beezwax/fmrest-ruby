require "faraday"
require "faraday_middleware"

require "fmdata/version"
require "fmdata/v1"

module FmData
  class << self
    attr_accessor :config
  end
end
