module FmData
  module V1
    # FM Data API authentication middleware using the credentials strategy
    #
    class TokenSession < Faraday::Middleware
      HEADER_KEY = "Authorization".freeze

      def initialize(app, options = FmData.config)
        super(app)
        @options = options
      end

      # Entry point for the middleware when sending a request
      #
      def call(env)
        env.request_headers[HEADER_KEY] = "Bearer #{token}"

        @app.call(env).on_complete do |response_env|
          if response_env[:status] == 401 # Unauthorized
            # Get new token and retry
            token_store.clear
            token
            return @app.call(env)
          end
        end
      end

      private

      # Tries to get an existing token from the token store,
      # otherwise requests one through basic auth,
      # otherwise raises an exception.
      #
      def token
        token = token_store.fetch
        return token if token

        if token = request_token
          token_store.store(token)
          return token
        end

        # TODO: Make this a custom exception class
        raise "Filemaker auth failed"
      end

      # Requests a token through basic auth
      #
      def request_token
        resp = auth_connection.post do |req|
          req.url V1.session_path(@options.fetch(:database))
          req.headers["Content-Type"] = "application/json"
        end
        return resp.body["response"]["token"] if resp.success?
        false
      end

      def token_store
        @token_store ||= token_store_class.new(@options.fetch(:host), @options.fetch(:database))
      end

      def token_store_class
        FmData.token_store ||
          begin
            # TODO: Make this less ugly
            require "fmdata/v1/token_store/memory"
            TokenStore::Memory
          end
      end

      def auth_connection
        @auth_connection ||= V1.base_connection(@options) do |conn|
          conn.basic_auth @options.fetch(:username), @options.fetch(:password)
          # TODO: Make logger optional
          conn.response   :logger, nil, bodies: true
          conn.response   :json
          conn.adapter    Faraday.default_adapter
        end
      end
    end
  end
end
