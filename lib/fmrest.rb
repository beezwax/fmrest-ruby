require "faraday"
require "faraday_middleware"

require "fmrest/version"
require "fmrest/v1"

module FmRest
  class << self
    attr_accessor :token_store

    attr_accessor :config
  end
end
