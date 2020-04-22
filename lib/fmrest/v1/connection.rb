# frozen_string_literal: true

require "uri"
require "fmrest/v1/token_session"
require "fmrest/v1/raise_errors"

module FmRest
  module V1
    module Connection
      BASE_PATH = "/fmi/data/v1/databases".freeze

      # Builds a complete DAPI Faraday connection with middleware already
      # configured to handle authentication, JSON parsing, logging and DAPI
      # error handling. A block can be optionally given for additional
      # middleware configuration
      #
      # @option options [String] :username The username for DAPI authentication
      # @option options [String] :account_name Alias of :username for
      #   compatibility with Rfm gem
      # @option options [String] :password The password for DAPI authentication
      # @option (see #base_connection)
      # @return (see #base_connection)
      def build_connection(options = FmRest.default_connection_settings, &block)
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

      # Builds a base Faraday connection with base URL constructed from
      # connection options and passes it the given block
      #
      # @option options [String] :host The hostname for the FM server
      # @option options [String] :database The FM database name
      # @option options [String] :ssl SSL options to forward to the Faraday
      #   connection
      # @option options [String] :proxy Proxy options to forward to the Faraday
      #   connection
      # @return [Faraday] The new Faraday connection
      def base_connection(options = FmRest.default_connection_settings, &block)
        host = options.fetch(:host)

        # Default to HTTPS
        scheme = "https"

        if host.match(/\Ahttps?:\/\//)
          uri = URI(host)
          host = uri.hostname
          host += ":#{uri.port}" if uri.port != uri.default_port
          scheme = uri.scheme
        end

        faraday_options = {}
        faraday_options[:ssl] = options[:ssl] if options.key?(:ssl)
        faraday_options[:proxy] = options[:proxy] if options.key?(:proxy)

        Faraday.new(
          "#{scheme}://#{host}#{BASE_PATH}/#{URI.escape(options.fetch(:database))}/".freeze,
          faraday_options,
          &block
        )
      end
    end
  end
end
