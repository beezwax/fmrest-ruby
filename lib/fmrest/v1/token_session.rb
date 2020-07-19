# frozen_string_literal: true

require "fmrest/v1/connection"
require "fmrest/errors"

module FmRest
  module V1
    # FM Data API authentication middleware using the credentials strategy
    #
    class TokenSession < Faraday::Middleware
      class NoSessionTokenSet < FmRest::Error; end

      HEADER_KEY = "Authorization".freeze
      TOKEN_STORE_INTERFACE = [:load, :store, :delete].freeze
      LOGOUT_PATH_MATCHER = %r{\A(#{FmRest::V1::Connection::BASE_PATH}/[^/]+/sessions/)[^/]+\Z}.freeze

      # @param app [#call]
      # @param settings [FmRest::ConnectionSettings]
      def initialize(app, settings)
        super(app)
        @settings = settings
      end

      # Entry point for the middleware when sending a request
      #
      def call(env)
        return handle_logout(env) if is_logout_request?(env)

        set_auth_header(env)

        request_body = env[:body] # After failure env[:body] is set to the response body

        @app.call(env).on_complete do |response_env|
          if response_env[:status] == 401 # Unauthorized
            env[:body] = request_body
            token_store.delete(token_store_key)
            set_auth_header(env)
            return @app.call(env)
          end
        end
      end

      private

      def handle_logout(env)
        token = token_store.load(token_store_key)

        raise NoSessionTokenSet, "Couldn't send logout request because no session token was set" unless token

        env.url.path = env.url.path.gsub(LOGOUT_PATH_MATCHER, "\\1#{token}")

        @app.call(env).on_complete do |response_env|
          if response_env[:status] == 200
            token_store.delete(token_store_key)
          end
        end
      end

      def is_logout_request?(env)
        return false unless env.method == :delete
        return env.url.path.match?(LOGOUT_PATH_MATCHER)
      end

      def set_auth_header(env)
        env.request_headers[HEADER_KEY] = "Bearer #{token}"
      end

      # Tries to get an existing token from the token store,
      # otherwise requests one through basic auth,
      # otherwise raises an exception.
      #
      def token
        token = token_store.load(token_store_key)
        return token if token

        if token = request_token
          token_store.store(token_store_key, token)
          return token
        end

        # TODO: Make this a custom exception class
        raise "Filemaker auth failed"
      end

      # Requests a token through basic auth
      #
      def request_token
        resp = auth_connection.post do |req|
          req.url V1.session_path
          req.headers["Content-Type"] = "application/json"
        end
        return resp.body["response"]["token"] if resp.success?
        false
      end

      # The key to use to store a token, uses the format host:database:username
      #
      def token_store_key
        @token_store_key ||=
          begin
            # Strip the host part to just the hostname (i.e. no scheme or port)
            host = @settings.host
            host = URI(host).hostname if host =~ /\Ahttps?:\/\//
            "#{host}:#{@settings.database}:#{@settings.username}"
          end
      end

      def token_store
        @token_store ||=
          begin
            if TOKEN_STORE_INTERFACE.all? { |method| token_store_option.respond_to?(method) }
              token_store_option
            elsif token_store_option.kind_of?(Class)
              token_store_option.new
            else
              require "fmrest/token_store/memory"
              TokenStore::Memory.new
            end
          end
      end

      def token_store_option
        @settings.token_store || FmRest.token_store
      end

      def auth_connection
        @auth_connection ||= V1.base_connection(@settings) do |conn|
          conn.basic_auth @settings.username, @settings.password

          if @settings.log
            conn.response :logger, nil, bodies: true, headers: true
          end

          conn.response :json
          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
