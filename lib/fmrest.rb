# frozen_string_literal: true

require "faraday"
require "faraday_middleware"

require "fmrest/version"
require "fmrest/connection_settings"
require "fmrest/errors"

module FmRest
  autoload :V1,         "fmrest/v1"
  autoload :TokenStore, "fmrest/token_store"
  autoload :Spyke,      "fmrest/spyke"
  autoload :Layout,     "fmrest/spyke"

  class << self
    attr_accessor :token_store
    attr_writer :logger

    def default_connection_settings=(settings)
      # Skip validation since we may use the defaults for half-complete
      # settings
      @default_connection_settings =
        ConnectionSettings.wrap(settings, skip_validation: true)
    end

    def default_connection_settings
      @default_connection_settings || ConnectionSettings.new({}, skip_validation: true)
    end

    def config=(connection_hash)
      warn "[DEPRECATION] `FmRest.config=` is deprecated, use `FmRest.default_connection_settings=` instead"
      self.default_connection_settings = connection_hash
    end

    def config
      warn "[DEPRECATION] `FmRest.config` is deprecated, use `FmRest.default_connection_settings` instead"
      default_connection_settings
    end

    def logger
      @logger ||= if defined?(Rails)
                    Rails.logger
                  else
                    require "logger"
                    Logger.new($stdout)
                  end
    end

    # Shortcut for FmRest::V1.escape_find_operators
    #
    # @param (see FmRest::V1.escape_find_operators
    # @return (see FmRest::V1.escape_find_operators
    def e(s)
      V1.escape_find_operators(s)
    end

    def Layout(*_)
      require "fmrest/spyke"
      self.Layout(*_)
    end
  end
end
