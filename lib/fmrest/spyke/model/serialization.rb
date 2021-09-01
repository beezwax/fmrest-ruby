# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module Serialization
        # Spyke override -- Return FM Data API's expected JSON format,
        # including only modified fields.
        #
        def to_params
          params = {
            fieldData: serialize_values!(changed_params_not_embedded_in_url).merge(serialize_portal_deletions)
          }

          params[:modId] = __mod_id.to_s if __mod_id

          portal_data = serialize_portals

          params[:portalData] = portal_data unless portal_data.empty?

          params
        end

        protected

        def serialize_for_portal(portal)
          params =
            changed_params.except(:__record_id).transform_keys do |key|
              V1.is_fully_qualified?(key) ? key : "#{portal.attribute_prefix}::#{key}"
            end

          params[:recordId] = __record_id.to_s if __record_id
          params[:modId] = __mod_id.to_s if __mod_id

          serialize_values!(params)
        end

        private

        def serialize_portals
          portal_data = {}

          portals.each do |portal|
            portal.each do |portal_record|
              next unless portal_record.changed? && !portal_record.marked_for_destruction?
              portal_params = portal_data[portal.portal_key] ||= []
              portal_params << portal_record.serialize_for_portal(portal)
            end
          end

          portal_data
        end

        def serialize_portal_deletions
          deletions = []

          portals.each do |portal|
            portal.select(&:marked_for_destruction?).each do |portal_record|
              next unless portal_record.persisted?
              deletions << "#{portal.portal_key}.#{portal_record.__record_id}"
            end
          end

          return {} if deletions.length == 0

          { deleteRelated: deletions.length == 1 ? deletions.first : deletions }
        end

        def changed_params_not_embedded_in_url
          params_not_embedded_in_url.slice(*mapped_changed)
        end

        # Modifies the given hash in-place encoding non-string values (e.g.
        # dates) to their string representation when appropriate.
        #
        # nil gets converted to empty string as the Data API doesn't accept
        # nulls in JSON. Likewise, true and false get converted to 1 and 0
        # respectively.
        #
        def serialize_values!(params)
          params.transform_values! do |value|
            case value
            when *FmRest::V1.datetime_classes
              FmRest::V1.convert_datetime_timezone(value.to_datetime, fmrest_config.timezone).strftime(FmRest::V1::Dates::FM_DATETIME_FORMAT)
            when *FmRest::V1.date_classes
              value.strftime(FmRest::V1::Dates::FM_DATE_FORMAT)
            when nil
              ""
            when true, false
              value ? 1 : 0
            else
              value
            end
          end

          params
        end
      end
    end
  end
end
