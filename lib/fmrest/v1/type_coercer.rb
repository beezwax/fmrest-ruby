# frozen_string_literal: true

require "fmrest/string_date"

module FmRest
  module V1
    class TypeCoercer < Faraday::Response::Middleware
      # We use this date to represent a FileMaker time for consistency with
      # ginjo-rfm
      JULIAN_ZERO_DAY = "-4712/1/1"

      COERCE_HYBRID = [:hybrid, "hybrid", true].freeze
      COERCE_FULL = [:full, "full"].freeze

      # @param app [#call]
      # @param settings [FmRest::ConnectionSettings]
      def initialize(app, settings)
        super(app)
        @settings = settings
      end

      def on_complete(env)
        return unless enabled?
        return unless env.body.kind_of?(Hash)

        data = env.body.dig("response", "data") || env.body.dig(:response, :data)

        return unless data

        data.each do |record|
          field_data = record["fieldData"] || record[:fieldData]
          portal_data = record["portalData"] || record[:portalData]

          coerce_fields(field_data)

          portal_data.try(:each_value) do |portal_records|
            portal_records.each do |pr|
              coerce_fields(pr)
            end
          end
        end
      end

      private

      def coerce_fields(hash)
        hash.each do |k, v|
          next unless v.is_a?(String)
          next if k == "recordId" || k == :recordId || k == "modId" || k == :modId

          if quick_check_timestamp(v)
            begin
              hash[k] = coerce_timestamp(v)
              next
            rescue ArgumentError
            end
          end

          if quick_check_date(v)
            begin
              hash[k] = date_class.strptime(v, date_strptime_format)
              next
            rescue ArgumentError
            end
          end

          if quick_check_time(v)
            begin
              hash[k] = datetime_class.strptime("#{JULIAN_ZERO_DAY} #{v}", time_strptime_format)
              next
            rescue ArgumentError
            end
          end
        end
      end

      def coerce_timestamp(str)
        str_timestamp = DateTime.strptime(str, datetime_strptime_format)

        if local_timezone?
          # Change the DateTime to the local timezone, keeping the same
          # time and just modifying the timezone
          offset = FmRest::V1.local_offset_for_datetime(str_timestamp)
          str_timestamp = str_timestamp.new_offset(offset) - offset
        end

        if datetime_class == StringDateTime
          str_timestamp = StringDateTime.new(str, str_timestamp)
        end

        str_timestamp
      end

      def date_class
        @date_class ||=
          case coerce_dates
          when *COERCE_HYBRID
            StringDate
          when *COERCE_FULL
            Date
          end
      end

      def datetime_class
        @datetime_class ||=
          case coerce_dates
          when *COERCE_HYBRID
            StringDateTime
          when *COERCE_FULL
            DateTime
          end
      end

      def date_fm_format
        @settings.date_format
      end

      def timestamp_fm_format
        @settings.timestamp_format
      end

      def time_fm_format
        @settings.time_format
      end

      def date_strptime_format
        FmRest::V1.fm_date_to_strptime_format(date_fm_format)
      end

      def datetime_strptime_format
        FmRest::V1.fm_date_to_strptime_format(timestamp_fm_format)
      end

      def time_strptime_format
        @time_strptime_format ||=
          "%Y/%m/%d " + FmRest::V1.fm_date_to_strptime_format(time_fm_format)
      end

      # We use a string length test, followed by regexp match test to try to
      # identify date fields. Benchmarking shows this should be between 1 and 3
      # orders of magnitude faster for fails (i.e. non-dates) than just using
      # Date.strptime.
      #
      #                       user     system      total        real
      # strptime:         0.268496   0.000962   0.269458 (  0.270865)
      # re=~:             0.024872   0.000070   0.024942 (  0.025057)
      # re.match?:        0.019745   0.000095   0.019840 (  0.020058)
      # strptime fail:    0.141309   0.000354   0.141663 (  0.142266)
      # re=~ fail:        0.031637   0.000095   0.031732 (  0.031872)
      # re.match? fail:   0.011249   0.000056   0.011305 (  0.011375)
      # length fail:      0.007177   0.000024   0.007201 (  0.007222)
      #
      # NOTE: The faster Regexp#match? was introduced in Ruby 2.4.0, so we
      # can't really rely on it being available
      if //.respond_to?(:match?)
        def quick_check_timestamp(v)
          v.length == timestamp_fm_format.length && FmRest::V1::fm_date_to_regexp(timestamp_fm_format).match?(v)
        end

        def quick_check_date(v)
          v.length == date_fm_format.length && FmRest::V1::fm_date_to_regexp(date_fm_format).match?(v)
        end

        def quick_check_time(v)
          v.length == time_fm_format.length && FmRest::V1::fm_date_to_regexp(time_fm_format).match?(v)
        end
      else
        def quick_check_timestamp(v)
          v.length == timestamp_fm_format.length && FmRest::V1::fm_date_to_regexp(timestamp_fm_format) =~ v
        end

        def quick_check_date(v)
          v.length == date_fm_format.length && FmRest::V1::fm_date_to_regexp(date_fm_format) =~ v
        end

        def quick_check_time(v)
          v.length == time_fm_format.length && FmRest::V1::fm_date_to_regexp(time_fm_format) =~ v
        end
      end

      def local_timezone?
        @local_timezone ||= @settings.timezone.try(:to_sym) == :local
      end

      def coerce_dates
        @settings.coerce_dates
      end

      alias_method :enabled?, :coerce_dates
    end
  end
end
