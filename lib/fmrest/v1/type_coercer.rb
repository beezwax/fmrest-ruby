# frozen_string_literal: true

require "fmrest/string_date"

module FmRest
  module V1
    class TypeCoercer < Faraday::Response::Middleware
      # We use this date to represent a time for consistency with ginjo-rfm
      JULIAN_ZERO_DAY = "-4712/1/1"

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

          enum.each do |hash|
            hash.each do |k, v|
              next unless v.is_a?(String)
              next if k == "recordId" || k == :recordId || k == "modId" || k == :modId

              begin
                str_timestamp = StringDateTime.new(v, datetime_format)
                hash[k] = str_timestamp
                next
              rescue StringDate::InvalidDate
              end

              begin
                str_date = StringDate.new(v, date_format)
                hash[k] = str_date
                next
              rescue StringDate::InvalidDate
              end

              begin
                str_time = StringDateTime.new("#{JULIAN_ZERO_DAY} #{v}", time_format)
                hash[k] = str_time
                next
              rescue StringDate::InvalidDate
              end
            end
          end
        end
      end

      private

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

      def enabled?
        @options.fetch(:coerce_dates, false)
      end
    end
  end
end
