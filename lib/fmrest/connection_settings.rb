# frozen_string_literal: true

module FmRest
  # Wrapper class for connection settings hash, with a number of purposes:
  #
  # * Provide indifferent access (base hash can have either string or symbol
  #   keys)
  # * Method access
  # * Default values
  # * Basic validation
  # * Normalization (e.g. aliased settings)
  # * Useful error messages
  class ConnectionSettings
    class MissingSetting < ArgumentError; end

    PROPERTIES = %i(
      host
      database
      username
      password
      fmid_token
      token
      token_store
      autologin
      ssl
      proxy
      log
      log_level
      coerce_dates
      date_format
      timestamp_format
      time_format
      timezone
      cognito_client_id
      cognito_pool_id
      aws_region
      cloud
    ).freeze

    # NOTE: password intentionally left non-required since it's only really
    # needed when no token exists, and should only be required when logging in
    REQUIRED = %i(
      host
      database
    ).freeze

    DEFAULT_DATE_FORMAT = "MM/dd/yyyy"
    DEFAULT_TIME_FORMAT = "HH:mm:ss"
    DEFAULT_TIMESTAMP_FORMAT = "#{DEFAULT_DATE_FORMAT} #{DEFAULT_TIME_FORMAT}"

    DEFAULTS = {
      autologin:        true,
      log:              false,
      log_level:        :debug,
      date_format:      DEFAULT_DATE_FORMAT,
      time_format:      DEFAULT_TIME_FORMAT,
      timestamp_format: DEFAULT_TIMESTAMP_FORMAT,
      coerce_dates:     false,
      cloud:            :auto,
    }.freeze

    def self.wrap(settings, skip_validation: false)
      if settings.kind_of?(self)
        settings.validate unless skip_validation
        return settings
      end
      new(settings, skip_validation: skip_validation)
    end

    def initialize(settings, skip_validation: false)
      @settings = settings.to_h.dup
      normalize
      validate unless skip_validation
    end

    PROPERTIES.each do |p|
      define_method(p) do
        get_eval(p)
      end

      define_method("#{p}!") do
        raise MissingSetting, "Missing required setting: `#{p}'" if get(p).nil?
        get_eval(p)
      end

      define_method("#{p}?") do
        !!get(p)
      end
    end

    def [](key)
      raise ArgumentError, "Unknown setting `#{key}'" unless PROPERTIES.include?(key.to_sym)
      get_eval(key)
    end

    def to_h
      PROPERTIES.each_with_object({}) do |p, h|
        v = get(p)
        h[p] = v unless v == DEFAULTS[p]
      end
    end

    def merge(other, **keyword_args)
      other = self.class.wrap(other, skip_validation: true)
      self.class.new(to_h.merge(other.to_h), **keyword_args)
    end

    def validate
      missing = REQUIRED.select { |r| get(r).nil? }.map { |m| "`#{m}'" }
      raise MissingSetting, "Missing required setting(s): #{missing.join(', ')}" unless missing.empty?

      unless username? || fmid_token? || token?
        raise MissingSetting, "A minimum of `username', `fmid_token' or `token' are required to be able to establish a connection"
      end
    end

    private

    def get_eval(key)
      c = get(key)
      c.kind_of?(Proc) ? c.call : c
    end

    def get(key)
      return @settings[key.to_sym] if @settings.has_key?(key.to_sym)
      return @settings[key.to_s] if @settings.has_key?(key.to_s)
      DEFAULTS[key.to_sym]
    end

    def normalize
      if !get(:username) && account_name = get(:account_name)
        @settings[:username] = account_name
      end
    end
  end
end
