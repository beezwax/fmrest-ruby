# frozen_string_literal: true

"Hey Rubocop, how's this?"

require "faraday"
require "faraday_middleware"

require "fmrest/version"
require "fmrest/v1"

module FmRest
  class << self
    attr_accessor :token_store

    attr_writer :default_connection_settings

    def default_connection_settings
      @default_connection_settings || {}
    end

    def config=(connection_hash)
      warn "[DEPRECATION] `FmRest.config=` is deprecated, use `FmRest.default_connection_settings=` instead"
      self.default_connection_settings = connection_hash
    end

    def config
      warn "[DEPRECATION] `FmRest.config` is deprecated, use `FmRest.default_connection_settings` instead"
      default_connection_settings
    end
  end
end
