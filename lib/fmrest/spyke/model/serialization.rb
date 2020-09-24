# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module Serialization
        FM_DATE_FORMAT = "%m/%d/%Y"
        FM_DATETIME_FORMAT = "#{FM_DATE_FORMAT} %H:%M:%S"

        # Override Spyke's to_params to return FM Data API's expected JSON
        # format, and including only modified fields
        #
        def to_params
          params = {
            fieldData: serialize_values!(changed_params_not_embedded_in_url)
          }

          params[:modId] = mod_id if mod_id

          portal_data = serialize_portals
          params[:portalData] = portal_data unless portal_data.empty?

          params
        end

        protected

        def serialize_for_portal(portal)
          params =
            changed_params.except(:id).transform_keys do |key|
              "#{portal.attribute_prefix}::#{key}"
            end

          params[:recordId] = id if id
          params[:modId] = mod_id if mod_id

          serialize_values!(params)
        end

        private

        def serialize_portals
          portal_data = {}

          portals.each do |portal|
            portal.each do |portal_record|
              next unless portal_record.changed?
              portal_params = portal_data[portal.portal_key] ||= []
              portal_params << portal_record.serialize_for_portal(portal)
            end
          end

          portal_data
        end

        def changed_params_not_embedded_in_url
          params_not_embedded_in_url.slice(*mapped_changed)
        end

        # Modifies the given hash in-place encoding non-string values (e.g.
        # dates) to their string representation when appropriate.
        #
        def serialize_values!(params)
          params.transform_values! do |value|
            case value
            when *datetime_classes
              convert_datetime_timezone(value.to_datetime).strftime(FM_DATETIME_FORMAT)
            when *date_classes
              value.strftime(FM_DATE_FORMAT)
            else
              value
            end
          end

          params
        end

        def convert_datetime_timezone(dt)
          case fmrest_config.timezone
          when :utc, "utc"
            dt.new_offset(0)
          when :local, "local"
            dt.new_offset(FmRest::V1.local_offset_for_datetime(dt))
          when nil
            dt
          end
        end

        def datetime_classes
          [DateTime, Time, defined?(FmRest::StringDateTime) && FmRest::StringDateTime].compact
        end

        def date_classes
          [Date, defined?(FmRest::StringDate) && FmRest::StringDate].compact
        end
      end
    end
  end
end
