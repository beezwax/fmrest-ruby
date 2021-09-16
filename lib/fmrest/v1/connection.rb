# frozen_string_literal: true

require "uri"

module FmRest
  module V1
    module Connection
      BASE_PATH = "/fmi/data/v1"
      DATABASES_PATH = "#{BASE_PATH}/databases"

      DEFAULT_HEADERS = { "User-Agent" => "fmrest-ruby/#{::FmRest::VERSION} Faraday/#{::Faraday::VERSION}" }.freeze
      AUTH_CONNECTION_HEADERS = DEFAULT_HEADERS.merge("Content-Type" => "application/json").freeze
      CLARIS_ID_HTTP_AUTH_TYPE = "FMID"

      # Builds a complete DAPI Faraday connection with middleware already
      # configured to handle authentication, JSON parsing, logging and DAPI
      # error handling. A block can be optionally given for additional
      # middleware configuration
      #
      # @option (see #base_connection)
      # @return (see #base_connection)
      def build_connection(settings = FmRest.default_connection_settings, &block)
        settings = ConnectionSettings.wrap(settings)

        base_connection(settings, headers: DEFAULT_HEADERS) do |conn|
          conn.use RaiseErrors
          conn.use TokenSession, settings

          # The EncodeJson and Multipart middlewares only encode the request
          # when the content type matches, so we can have them both here and
          # still play nice with each other, we just need to set the content
          # type to multipart/form-data when we want to submit a container
          # field
          conn.request :multipart
          conn.request :json

          # Allow overriding the default response middleware
          if block_given?
            yield conn, settings
          else
            conn.use TypeCoercer, settings
            conn.response :json, content_type: /\bjson$/
          end

          if settings.log
            conn.response :logger, FmRest.logger, bodies: true, headers: true, log_level: settings.log_level
          end

          conn.adapter Faraday.default_adapter
        end
      end

      # Builds a Faraday connection to use for DAPI basic auth login
      #
      # @option (see #base_connection)
      # @return (see #base_connection)
      def auth_connection(settings = FmRest.default_connection_settings)
        settings = ConnectionSettings.wrap(settings)

        base_connection(settings, headers: AUTH_CONNECTION_HEADERS) do |conn|
          conn.use RaiseErrors

          if settings.fmid_token?
            conn.request :authorization, CLARIS_ID_HTTP_AUTH_TYPE, settings.fmid_token
          else
            conn.request :basic_auth, settings.username!, settings.password!
          end

          if settings.log
            conn.response :logger, FmRest.logger, bodies: true, headers: true, log_level: settings.log_level
          end

          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end

      # Builds a base Faraday connection with base URL constructed from
      # connection settings and passes it the given block
      #
      # @option settings [String] :host The hostname for the FM server
      # @option settings [String] :database The FM database name
      # @option settings [String] :username The username for DAPI authentication
      # @option settings [String] :account_name Alias of :username for
      #   compatibility with Rfm gem
      # @option settings [String] :password The password for DAPI authentication
      # @option settings [String] :ssl SSL settings to forward to the Faraday
      #   connection
      # @option settings [String] :proxy Proxy options to forward to the Faraday
      #   connection
      # @param faraday_options [Hash] additional options for Faraday object
      # @return [Faraday] The new Faraday connection
      def base_connection(settings = FmRest.default_connection_settings, faraday_options = nil, &block)
        settings = ConnectionSettings.wrap(settings)

        host = settings.host!

        # Default to HTTPS
        scheme = "https"

        if host.match(/\Ahttps?:\/\//)
          uri = URI(host)
          host = uri.hostname
          host += ":#{uri.port}" if uri.port != uri.default_port
          scheme = uri.scheme
        end

        faraday_options = (faraday_options || {}).dup
        faraday_options[:ssl] = settings.ssl if settings.ssl?
        faraday_options[:proxy] = settings.proxy if settings.proxy?

        database = V1.url_encode(settings.database!)

        Faraday.new(
          "#{scheme}://#{host}#{DATABASES_PATH}/#{database}/".freeze,
          faraday_options,
          &block
        )
      end
    end
  end
end
