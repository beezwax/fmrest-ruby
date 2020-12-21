# frozen_string_literal: true

module FmRest
  module V1
    module Paths
      def session_path(token = nil)
        url = "sessions"
        url += "/#{token}" if token
        url
      end

      def record_path(layout, id = nil)
        url = "layouts/#{V1.url_encode(layout)}/records"
        url += "/#{id}" if id
        url
      end

      def container_field_path(layout, id, field_name, field_repetition = 1)
        url = record_path(layout, id)
        url += "/containers/#{V1.url_encode(field_name)}"
        url += "/#{field_repetition}" if field_repetition
        url
      end

      def find_path(layout)
        "layouts/#{V1.url_encode(layout)}/_find"
      end

      def script_path(layout, script)
        "layouts/#{V1.url_encode(layout)}/script/#{V1.url_encode(script)}"
      end

      def globals_path
        "globals"
      end

      def product_info_path
        "#{V1::Connection::BASE_PATH}/productInfo"
      end
    end
  end
end
