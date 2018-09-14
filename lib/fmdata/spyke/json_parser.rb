module FmData
  module Spyke
    class JsonParser < ::Faraday::Response::Middleware
      SINGLE_RECORD_RE = %r(/records/\d+\Z).freeze

      def on_complete(env)
        json = parse_json(env.body)

        env.body = if single_record_url?(env.url)
                     prepare_single_record(json)
                   else
                     prepare_collection(json)
                   end
      end

      private

      def prepare_single_record(json)
        data =
          json[:response][:data] &&
          prepare_record_data(json[:response][:data].first)

        base_hash(json).merge!(data: data)
      end

      def prepare_collection(json)
        data =
          json[:response][:data] &&
          json[:response][:data].map { |record_data| prepare_record_data(record_data) }

        base_hash(json).merge!(data: data)
      end

      def base_hash(json)
        {
          metadata: { messages: json[:messages] },
          errors:   {}
        }
      end

      def prepare_record_data(json_data)
        { id: json_data[:recordId].to_i }.merge!(json_data[:fieldData])
      end

      def single_record_url?(url)
        url.path.match(SINGLE_RECORD_RE)
      end

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
