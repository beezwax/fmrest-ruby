# frozen_string_literal: true

module FmRest
  module Spyke
    # Response Faraday middleware for converting FM API's response JSON into
    # Spyke's expected format
    class JsonParser < ::Faraday::Response::Middleware
      SINGLE_RECORD_RE = %r(/records/\d+\Z).freeze
      MULTIPLE_RECORDS_RE = %r(/records\Z).freeze
      FIND_RECORDS_RE = %r(/_find\b).freeze

      VALIDATION_ERROR_RANGE = 500..599

      # @param app [#call]
      # @param model [Class<FmRest::Spyke::Base>]
      def initialize(app, model)
        super(app)
        @model = model
      end

      # @param env [Faraday::Env]
      def on_complete(env)
        json = parse_json(env.body)

        case
        when single_record_request?(env)
          env.body = prepare_single_record(json)
        when multiple_records_request?(env), find_request?(env)
          env.body = prepare_collection(json)
        when create_request?(env), update_request?(env), delete_request?(env)
          env.body = prepare_save_response(json)
        end
      end

      private

      # @param json [Hash]
      # @return [Hash] the response in Spyke format
      def prepare_save_response(json)
        response = json[:response]

        data = {}
        data[:mod_id] = response[:modId] if response[:modId]
        data[:id]     = response[:recordId].to_i if response[:recordId]

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
      # @return [Hash] the skeleton structure for a Spyke-formatted response
      def build_base_hash(json, include_errors = false)
        {
          metadata: { messages: json[:messages] },
          errors:   include_errors ? prepare_errors(json) : {}
        }
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
        out = { id: json_data[:recordId].to_i, mod_id: json_data[:modId] }
        out.merge!(json_data[:fieldData])
        out.merge!(prepare_portal_data(json_data[:portalData])) if json_data[:portalData]
        out
      end

      # Extracts `recordId` and strips the `"PortalName::"` field prefix for each
      # portal
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

          out[portal_name] =
            portal_records.map do |portal_fields|
              attributes = { id: portal_fields[:recordId].to_i }
              attributes[:mod_id] = portal_fields[:modId] if portal_fields[:modId]

              prefix = portal_options[:attribute_prefix] || portal_name
              prefix_matcher = /\A#{prefix}::/

              portal_fields.each do |k, v|
                next if :recordId == k || :modId == k
                attributes[k.to_s.gsub(prefix_matcher, "").to_sym] = v
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
      def delete_request?(env)
        env.method == :delete && env.url.path.match(SINGLE_RECORD_RE)
      end

      # @param source [String] a JSON string
      # @return [Hash] the parsed JSON
      def parse_json(source)
        if defined?(::MultiJson)
          ::MultiJson.load(source, symbolize_keys: true)
        else
          ::JSON.parse(source, symbolize_names: true)
        end
      end
    end
  end
end
