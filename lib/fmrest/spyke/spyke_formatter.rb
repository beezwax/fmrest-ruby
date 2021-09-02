# frozen_string_literal: true

require "json"
require "ostruct"

module FmRest
  module Spyke
    # Metadata class to be passed to Spyke::Collection#metadata
    class Metadata < Struct.new(:messages, :script, :data_info)
      alias_method :scripts, :script
    end

    class DataInfo < OpenStruct
      def total_record_count; totalRecordCount; end
      def found_count; foundCount; end
      def returned_count; returnedCount; end
    end

    # Response Faraday middleware for converting FM API's response JSON into
    # Spyke's expected format
    class SpykeFormatter < ::Faraday::Response::Middleware
      SINGLE_RECORD_RE = %r(/records/\d+\z).freeze
      MULTIPLE_RECORDS_RE = %r(/records\z).freeze
      CONTAINER_RE = %r(/records/\d+/containers/[^/]+/\d+\z).freeze
      FIND_RECORDS_RE = %r(/_find\b).freeze
      SCRIPT_REQUEST_RE = %r(/script/[^/]+\z).freeze

      VALIDATION_ERROR_RANGE = 500..599

      # @param app [#call]
      # @param model [Class<FmRest::Spyke::Base>]
      def initialize(app, model)
        super(app)
        @model = model
      end

      # @param env [Faraday::Env]
      def on_complete(env)
        return unless env.body.is_a?(Hash)

        json = env.body

        case
        when single_record_request?(env)
          env.body = prepare_single_record(json)
        when multiple_records_request?(env), find_request?(env)
          env.body = prepare_collection(json)
        when create_request?(env), update_request?(env), delete_request?(env), container_upload_request?(env)
          env.body = prepare_save_response(json)
        when execute_script_request?(env)
          env.body = build_base_hash(json)
        else
          # Attempt to parse unknown requests too
          env.body = build_base_hash(json)
        end
      end

      private

      # @param json [Hash]
      # @return [Hash] the response in Spyke format
      def prepare_save_response(json)
        response = json[:response]

        data = {}
        data[:__mod_id] = response[:modId] if response[:modId]
        data[:__record_id] = response[:recordId] if response[:recordId]
        data[:__new_portal_record_info] = response[:newPortalRecordInfo] if response[:newPortalRecordInfo]

        build_base_hash(json, true).merge!(data: data)
      end

      # (see #prepare_save_response)
      def prepare_single_record(json)
        data =
          json[:response][:data] &&
          prepare_record_data(json[:response][:data].first)

        build_base_hash(json).merge!(data: data)
      end

      # (see #prepare_save_response)
      def prepare_collection(json)
        data =
          json[:response][:data] &&
          json[:response][:data].map { |record_data| prepare_record_data(record_data) }

        build_base_hash(json).merge!(data: data)
      end

      # @param json [Hash]
      # @param include_errors [Boolean]
      # @return [FmRest::Spyke::Metadata] the skeleton structure for a
      #   Spyke-formatted response
      def build_base_hash(json, include_errors = false)
        {
          metadata: Metadata.new(
            prepare_messages(json),
            prepare_script_results(json),
            prepare_data_info(json)
          ).freeze,
          errors: include_errors ? prepare_errors(json) : {}
        }
      end

      # @param json [Hash]
      # @return [Array<OpenStruct>] the skeleton structure for a
      #   Spyke-formatted response
      def prepare_messages(json)
        return [] unless json[:messages]
        json[:messages].map { |m| OpenStruct.new(m).freeze }.freeze
      end

      # @param json [Hash]
      # @return [OpenStruct] the script(s) execution results for Spyke metadata
      #   format
      def prepare_script_results(json)
        results = {}

        [:prerequest, :presort].each do |s|
          if json[:response][:"scriptError.#{s}"]
            results[s] = OpenStruct.new(
              result: json[:response][:"scriptResult.#{s}"],
              error:  json[:response][:"scriptError.#{s}"]
            ).freeze
          end
        end

        if json[:response][:scriptError]
          results[:after] = OpenStruct.new(
            result: json[:response][:scriptResult],
            error:  json[:response][:scriptError]
          ).freeze
        end

        results.present? ? OpenStruct.new(results).freeze : nil
      end

      # @param json [Hash]
      # @return [OpenStruct] the script(s) execution results for
      #   Spyke metadata format
      def prepare_data_info(json)
        data_info = json[:response] && json[:response][:dataInfo]

        return nil unless data_info.present?

        DataInfo.new(data_info).freeze
      end

      # @param json [Hash]
      # @return [Hash] the errors hash in Spyke format
      def prepare_errors(json)
        # Code 0 means "No Error"
        # https://fmhelp.filemaker.com/help/17/fmp/en/index.html#page/FMP_Help/error-codes.html
        return {} if json[:messages][0][:code].to_i == 0

        json[:messages].each_with_object(base: []) do |message, hash|
          # Only include validation errors
          next unless VALIDATION_ERROR_RANGE.include?(message[:code].to_i)

          hash[:base] << "#{message[:message]} (#{message[:code]})"
        end
      end

      # `json_data` is expected in this format:
      #
      #     {
      #       "fieldData": {
      #         "fieldName1" : "fieldValue1",
      #         "fieldName2" : "fieldValue2",
      #         ...
      #       },
      #       "portalData": {
      #         "portal1" : [
      #           { <portalRecord1> },
      #           { <portalRecord2> },
      #           ...
      #         ],
      #         "portal2" : [
      #           { <portalRecord1> },
      #           { <portalRecord2> },
      #           ...
      #         ]
      #       },
      #       "modId": <Id_for_last_modification>,
      #       "recordId": <Unique_internal_ID_for_this_record>
      #     }
      #
      # @param json_data [Hash]
      # @return [Hash] the record data in Spyke format
      def prepare_record_data(json_data)
        out = { __record_id: json_data[:recordId], __mod_id: json_data[:modId] }
        out.merge!(json_data[:fieldData])
        out.merge!(prepare_portal_data(json_data[:portalData])) if json_data[:portalData]
        out
      end

      # Extracts `recordId` and strips the `"tableName::"` field qualifier for
      # each portal
      #
      # Sample `json_portal_data`:
      #
      #     "portalData": {
      #       "Orders":[
      #         { "Orders::DeliveryDate": "3/7/2017", "recordId": "23" }
      #       ]
      #     }
      #
      # @param json_portal_data [Hash]
      # @return [Hash] the portal data in Spyke format
      def prepare_portal_data(json_portal_data)
        json_portal_data.each_with_object({}) do |(portal_name, portal_records), out|

          portal_options = @model.portal_options[portal_name.to_s] || {}
          portal_builder = portal_options[:name] && @model.associations[portal_options[:name].to_sym]
          portal_class = portal_builder && portal_builder.klass
          portal_attributes = (portal_class && portal_class.mapped_attributes.values) || []

          out[portal_name] =
            portal_records.map do |portal_fields|
              attributes = { __record_id: portal_fields[:recordId] }
              attributes[:__mod_id] = portal_fields[:modId] if portal_fields[:modId]

              qualifier = portal_options[:attribute_prefix] || portal_name
              qualifier_matcher = /\A#{qualifier}::/

              portal_fields.each do |k, v|
                next if :recordId == k || :modId == k

                stripped_field_name = k.to_s.gsub(qualifier_matcher, "")

                # Only use the non-qualified attribute name if it was defined
                # that way on the portal model, otherwise default to the fully
                # qualified name
                if portal_attributes.include?(stripped_field_name)
                  attributes[stripped_field_name.to_sym] = v
                else
                  attributes[k.to_sym] = v
                end
              end

              attributes
            end
        end
      end

      # @param env [Faraday::Env]
      # @return [Boolean]
      def single_record_request?(env)
        env.method == :get && env.url.path.match(SINGLE_RECORD_RE)
      end

      # (see #single_record_request?)
      def multiple_records_request?(env)
        env.method == :get && env.url.path.match(MULTIPLE_RECORDS_RE)
      end

      # (see #single_record_request?)
      def find_request?(env)
        env.method == :post && env.url.path.match(FIND_RECORDS_RE)
      end

      # (see #single_record_request?)
      def update_request?(env)
        env.method == :patch && env.url.path.match(SINGLE_RECORD_RE)
      end

      # (see #single_record_request?)
      def create_request?(env)
        env.method == :post && env.url.path.match(MULTIPLE_RECORDS_RE)
      end

      # (see #single_record_request?)
      def container_upload_request?(env)
        env.method == :post && env.url.path.match(CONTAINER_RE)
      end

      # (see #single_record_request?)
      def delete_request?(env)
        env.method == :delete && env.url.path.match(SINGLE_RECORD_RE)
      end

      def execute_script_request?(env)
        env.method == :get && env.url.path.match(SCRIPT_REQUEST_RE)
      end
    end
  end
end
