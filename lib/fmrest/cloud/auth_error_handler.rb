# frozen_string_literal: true

module FmRest
  module Cloud
    class AuthErrorHandler < Faraday::Response::Middleware
      def initialize(app, settings)
        super(app)
        @settings = settings
      end

      def call(env)
        begin
          @app.call(env)
        rescue APIError::AccountError => e
          ClarisIdTokenManager.new(@settings).expire_token
          @app.call(env)
        end
      end
    end
  end
end
