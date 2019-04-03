# frozen_string_literal: true

require "uri"
require "fmrest/v1/token_session"
require "fmrest/v1/raise_errors"

module FmRest
  module V1
    module Connection
      BASE_PATH = "/fmi/data/v1/databases".freeze

      def build_connection(options = FmRest.config, &block)
        base_connection(options) do |conn|
          conn.use RaiseErrors
          conn.use TokenSession, options

          # The EncodeJson and Multipart middlewares only encode the request
          # when the content type matches, so we can have them both here and
          # still play nice with each other, we just need to set the content
          # type to multipart/form-data when we want to submit a container
          # field
          conn.request :multipart
          conn.request :json

          if options[:log]
            conn.response :logger, nil, bodies: true, headers: true
          end

          # Allow overriding the default response middleware
          if block_given?
            yield conn
          else
            conn.response :json
          end

          conn.adapter Faraday.default_adapter
        end
      end

      def base_connection(options = FmRest.config, &block)
        host = options.fetch(:host)

        # Default to HTTPS
        scheme = "https"

        if host.match(/\Ahttps?:\/\//)
          uri = URI(host)
          host = uri.hostname
          host += ":#{uri.port}" if uri.port != uri.default_port
          scheme = uri.scheme
        end

        Faraday.new("#{scheme}://#{host}#{BASE_PATH}/#{URI.escape(options.fetch(:database))}/".freeze, &block)
      end
    end
  end
end
