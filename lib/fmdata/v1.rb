require "fmdata/v1/token_session"
require "uri"

module FmData
  module V1
    BASE_PATH = "/fmi/data/v1/databases/".freeze

    class << self
      def build_connection(options = FmData.config, &block)
        base_connection(options) do |conn|
          conn.use      TokenSession, options
          conn.request  :json

          # TODO: Make logger optional
          conn.response :logger, nil, bodies: true

          # Allow overriding the default response middleware
          if block_given?
            yield conn
          else
            conn.response :json
          end

          conn.adapter  Faraday.default_adapter
        end
      end

      def base_connection(options = FmData.config, &block)
        # TODO: Make HTTPS optional
        Faraday.new("https://" + options.fetch(:host) + BASE_PATH, &block)
      end

      def session_path(database, token = nil)
        url = "#{URI.escape(database)}/sessions"
        url += "/#{token}" if token
        url
      end

      def record_path(database, layout, id = nil)
        url = "#{URI.escape(database)}/layouts/#{URI.escape(layout)}/records"
        url += "/#{id}" if id
        url
      end

      #def find_path
      #end

      #def globals_path
      #end
    end
  end
end
