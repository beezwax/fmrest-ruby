# frozen_string_literal: true

module FmRest
  module V1
    module Dates
      FM_DATE_FORMAT = "%m/%d/%Y"
      FM_DATETIME_FORMAT = "#{FM_DATE_FORMAT} %H:%M:%S"
      FM_DATETIME_FORMAT_MATCHER = /MM|mm|dd|HH|ss|yyyy/.freeze

      FM_DATE_TO_STRPTIME_SUBSTITUTIONS = {
        "MM"   => "%m",
        "dd"   => "%d",
        "yyyy" => "%Y",
        "HH"   => "%H",
        "mm"   => "%M",
        "ss"   => "%S"
      }.freeze

      FM_DATE_TO_REGEXP_SUBSTITUTIONS = {
        "MM"   => '(?:0[1-9]|1[012])',
        "dd"   => '(?:0[1-9]|[12][0-9]|3[01])',
        "yyyy" => '\d{4}',
        "HH"   => '(?:[01]\d|2[0123])',
        "mm"   => '[0-5]\d',
        "ss"   => '[0-5]\d'
      }.freeze

      def self.extended(mod)
        mod.instance_eval do
          @date_strptime = {}
          @date_regexp = {}
        end
      end

      # Converts a FM date-time format to `DateTime.strptime` format
      #
      # @param fm_format [String] The FileMaker date-time format
      # @return [String] The `DateTime.strpdate` equivalent of the given FM
      #   date-time format
      def fm_date_to_strptime_format(fm_format)
        @date_strptime[fm_format] ||=
          fm_format.gsub(FM_DATETIME_FORMAT_MATCHER, FM_DATE_TO_STRPTIME_SUBSTITUTIONS).freeze
      end

      # Converts a FM date-time format to a Regexp. This is mostly used a
      # quicker way of checking whether a FM field is a date field than
      # Date|DateTime.strptime
      #
      # @param fm_format [String] The FileMaker date-time format
      # @return [Regexp] A reegular expression matching strings in the given FM
      #   date-time format
      def fm_date_to_regexp(fm_format)
        @date_regexp[fm_format] ||= 
          Regexp.new('\A' + fm_format.gsub(FM_DATETIME_FORMAT_MATCHER, FM_DATE_TO_REGEXP_SUBSTITUTIONS) + '\Z').freeze
      end

      # Takes a DateTime dt, and returns the correct local offset for that dt,
      # daylight savings included, in fraction of a day.
      #
      # By default, if ActiveSupport's `Time.zone` is set it will be used
      # instead of the system timezone.
      #
      # @param dt [DateTime] The DateTime to get the offset for
      # @param zone [nil, String, TimeZone] The timezone to use to calculate
      #   the offset (defaults to system timezone, or ActiveSupport's Time.zone
      #   if set)
      # @return [Rational] The offset in fraction of a day
      def local_offset_for_datetime(dt, zone = nil)
        dt = dt.new_offset(0)
        time = ::Time.utc(dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec)

        # Do we have ActiveSupport's TimeZone?
        time = if time.respond_to?(:in_time_zone)
                 time.in_time_zone(zone || ::Time.zone)
               else
                 time.localtime
               end

        Rational(time.utc_offset, 86400) # seconds in one day (24*60*60)
      end

      # Returns a list of all datetime classes recognized by fmrest-ruby,
      # including `FmRest::StringDateTime` if defined. Useful for using in a
      # `case .. when` statement.
      #
      def datetime_classes
        [DateTime, Time, defined?(FmRest::StringDateTime) && FmRest::StringDateTime].compact.freeze
      end

      # Returns a list of all date classes recognized by fmrest-ruby, including
      # `FmRest::StringDate` if defined. Useful for using in a `case .. when`
      # statement.
      #
      def date_classes
        [Date, defined?(FmRest::StringDate) && FmRest::StringDate].compact.freeze
      end

      # Converts the given DateTime dt to the specified timezone setting offset,
      # leaving everything else intact.
      #
      # @param dt [DateTime] The datetime to convert
      # @param timezone [nil, Symbol, String] Accepted values are `:utc`,
      #   `:local`, or `nil` (in which case it leaves the given datetime intact)
      # @return [DateTime] A new datetime with converted timezone
      def convert_datetime_timezone(dt, timezone)
        case timezone
        when :utc, "utc"
          dt.new_offset(0)
        when :local, "local"
          dt.new_offset(FmRest::V1.local_offset_for_datetime(dt))
        when nil
          dt
        end
      end
    end
  end
end
