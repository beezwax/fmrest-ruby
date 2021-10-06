# frozen_string_literal: true

module FmRest
  module Cloud
    class AuthErrorHandler < Faraday::Middleware
      def initialize(app, settings)
        super(app)
        @settings = settings
      end

      def call(env)
        request_body = env[:body] # After failure env[:body] is set to the response body
        @app.call(env)
      rescue APIError::AccountError => e
        ClarisIdTokenManager.new(@settings).expire_token
        # Faraday::Request::Authorization will not get a new token if the
        # Authorization header is already set
        env.request_headers.delete("Authorization")
        env[:body] = request_body
        @app.call(env)
      end
    end
  end
end
