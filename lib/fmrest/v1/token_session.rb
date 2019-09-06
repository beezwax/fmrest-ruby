# frozen_string_literal: true

module FmRest
  module V1
    # FM Data API authentication middleware using the credentials strategy
    #
    class TokenSession < Faraday::Middleware
      HEADER_KEY = "Authorization".freeze
      TOKEN_STORE_INTERFACE = [:load, :store, :delete].freeze

      def initialize(app, options = FmRest.default_connection_settings)
        super(app)
        @options = options
      end

      # Entry point for the middleware when sending a request
      #
      def call(env)
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

      # The key to use to store a token, uses the format host:database
      #
      def token_store_key
        @token_store_key ||=
          begin
            # Strip the host part to just the hostname (i.e. no scheme or port)
            host = @options.fetch(:host)
            host = URI(host).hostname if host =~ /\Ahttps?:\/\//
            "#{host}:#{@options.fetch(:database)}"
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
        @options[:token_store] || FmRest.token_store
      end

      def auth_connection
        @auth_connection ||= V1.base_connection(@options) do |conn|
          conn.basic_auth @options.fetch(:username), @options.fetch(:password)

          if @options[:log]
            conn.response :logger, nil, bodies: true, headers: true
          end

          conn.response :json
          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
