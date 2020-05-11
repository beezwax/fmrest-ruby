# frozen_string_literal: true

require "fmrest/string_date"

module FmRest
  module V1
    class TypeCoercer < Faraday::Response::Middleware
      # We use this date to represent a time for consistency with ginjo-rfm
      JULIAN_ZERO_DAY = "-4712/1/1"

      COERCE_HYBRID = [:hybrid, "hybrid", true].freeze
      COERCE_FULL = [:full, "full"].freeze

      # @param app [#call]
      # @param options [Hash]
      def initialize(app, options = FmRest.default_connection_settings)
        super(app)
        @options = options
      end

      def on_complete(env)
        return unless enabled?
        return unless env.body.kind_of?(Hash)

        data = env.body.dig("response", "data") || env.body.dig(:response, :data)

        return unless data

        data.each do |record|
          field_data = record["fieldData"] || record[:fieldData]
          portal_data = record["portalData"] || record[:portalData]

          # Build an enumerator that iterates over hashes of fields
          enum = Enumerator.new { |y| y << field_data }
          if portal_data
            portal_data.each_value do |portal_records|
              enum += portal_records.to_enum
            end
          end

          enum.each { |hash| coerce_fields(hash) }
        end
      end

      private

      def coerce_fields(hash)
        hash.each do |k, v|
          next unless v.is_a?(String)
          next if k == "recordId" || k == :recordId || k == "modId" || k == :modId

          begin
            str_timestamp = datetime_class.strptime(v, datetime_format)
            hash[k] = str_timestamp
            next
          rescue ArgumentError
          end

          begin
            str_date = date_class.strptime(v, date_format)
            hash[k] = str_date
            next
          rescue ArgumentError
          end

          begin
            str_time = datetime_class.strptime("#{JULIAN_ZERO_DAY} #{v}", time_format)
            hash[k] = str_time
            next
          rescue ArgumentError
          end
        end
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

      def date_format
        @date_format ||=
          FmRest::V1.convert_date_time_format(@options[:date_format] || DEFAULT_DATE_FORMAT)
      end

      def datetime_format
        @datetime_format ||=
          FmRest::V1.convert_date_time_format(@options[:timestamp_format] || DEFAULT_TIMESTAMP_FORMAT)
      end

      def time_format
        @time_format ||=
          "%Y/%m/%d " + FmRest::V1.convert_date_time_format(@options[:time_format] || DEFAULT_TIME_FORMAT)
      end

      def coerce_dates
        @options.fetch(:coerce_dates, false)
      end

      alias_method :enabled?, :coerce_dates
    end
  end
end
