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
        url = "layouts/#{url_encode(layout)}/records"
        url += "/#{id}" if id
        url
      end

      def container_field_path(layout, id, field_name, field_repetition = 1)
        url = record_path(layout, id)
        url += "/containers/#{url_encode(field_name)}"
        url += "/#{field_repetition}" if field_repetition
        url
      end

      def find_path(layout)
        "layouts/#{url_encode(layout)}/_find"
      end

      def script_path(layout, script)
        "layouts/#{url_encode(layout)}/script/#{url_encode(script)}"
      end

      def globals_path
        "globals"
      end

      private

      # Borrowed from ERB::Util
      def url_encode(s)
        s.to_s.b.gsub(/[^a-zA-Z0-9_\-.]/n) { |m|
          sprintf("%%%02X", m.unpack("C")[0])
        }
      end
    end
  end
end
