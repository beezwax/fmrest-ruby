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
    class ValidationError < ArgumentError; end

    PROPERTIES = %i(
      host
      database
      username
      password
      token_store
      ssl
      proxy
      log
      coerce_dates
      date_format
      timestamp_format
      time_format
      timezone
    ).freeze

    REQUIRED = %i(
      host
      database
      username
      password
    ).freeze

    DEFAULT_DATE_FORMAT = "MM/dd/yyyy"
    DEFAULT_TIME_FORMAT = "HH:mm:ss"
    DEFAULT_TIMESTAMP_FORMAT = "#{DEFAULT_DATE_FORMAT} #{DEFAULT_TIME_FORMAT}"

    DEFAULTS = {
      log:              false,
      date_format:      DEFAULT_DATE_FORMAT,
      time_format:      DEFAULT_TIME_FORMAT,
      timestamp_format: DEFAULT_TIMESTAMP_FORMAT,
      coerce_dates:     false
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
        get(p)
      end

      define_method("#{p}?") do
        !!get(p)
      end
    end

    def [](key)
      raise ArgumentError, "Unknown property `#{key}'" unless PROPERTIES.include?(key.to_sym)
      get(key)
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
      raise ValidationError, "Missing required: #{missing.join(', ')}" unless missing.empty?
    end

    private

    def get(key)
      @settings[key.to_sym] || @settings[key.to_s] || DEFAULTS[key.to_sym]
    end

    def normalize
      if !get(:username) && account_name = get(:account_name)
        @settings[:username] = account_name
      end
    end
  end
end
