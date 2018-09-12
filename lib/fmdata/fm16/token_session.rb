require "fmdata/fm16/session_token_store"

module FmData
  module FM16
    # FM Data API authentication middleware using the credentials strategy
    #
    class TokenSession < Faraday::Middleware
      HEADER_KEY = "FM-Data-Token".freeze

      def initialize(app, options = {})
        super(app)
        @options = options.reverse_merge(FmData.config)
      end

      def call(env)
        env.request_headers[HEADER_KEY] = token

        catch :auth_failed do
          @app.call(env).on_complete do |response_env|
            throw :auth_failed if response_env[:status] != 200
          end

          return
        end

        # Get token and retry
        token
        @app.call(env)
      end

      private

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

      def request_token
        resp = auth_connection.post do |req|
          req.url FM16.build_path(:auth, @options.fetch(:database))
          req.body = {
            user:     @options.fetch(:username),
            password: @options.fetch(:password),
            layout:   @options.fetch(:layout)
          }
        end

        return resp.body["token"] if resp.success?

        false
      end

      def token_store
        @options[:token_store] || SessionTokenStore.new
      end

      def auth_connection
        @auth_connection ||= FM16.base_connection(@options) do |conn|
          conn.request    :json
          conn.response   :logger, nil, bodies: true
          conn.response   :json
          conn.adapter    Faraday.default_adapter
        end
      end
    end
  end
end
