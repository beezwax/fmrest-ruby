# frozen_string_literal: true

require "fmrest/v1/connection"

module FmRest
  module V1
    # FM Data API authentication middleware using the credentials strategy
    #
    class TokenSession < Faraday::Middleware
      include TokenStore

      class NoSessionTokenSet < FmRest::Error; end

      HEADER_KEY = "Authorization"
      LOGOUT_PATH_MATCHER = %r{\A(#{FmRest::V1::Connection::DATABASES_PATH}/[^/]+/sessions/)[^/]+\Z}.freeze

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
            delete_token_store_key

            if @settings.autologin
              env[:body] = request_body
              set_auth_header(env)
              return @app.call(env)
            end
          end
        end
      end

      private

      def delete_token_store_key
        token_store.delete(token_store_key)
        # Sometimes we may want to pass the :token in settings manually, and
        # refrain from passing a :username. In that case the call to
        # #token_store_key above would fail as it tries to fetch :username, so
        # we purposely ignore that error.
      rescue FmRest::ConnectionSettings::MissingSetting
      end

      def handle_logout(env)
        token = @settings.token? ? @settings.token : token_store.load(token_store_key)

        raise NoSessionTokenSet, "Couldn't send logout request because no session token was set" unless token

        env.url.path = env.url.path.gsub(LOGOUT_PATH_MATCHER, "\\1#{token}")

        @app.call(env).on_complete do |response_env|
          delete_token_store_key if response_env[:status] == 200
        end
      end

      def is_logout_request?(env)
        return false unless env.method == :delete
        return env.url.path.match?(LOGOUT_PATH_MATCHER)
      end

      def set_auth_header(env)
        env.request_headers[HEADER_KEY] = "Bearer #{token}"
      end

      # Uses the token given in connection settings if available,
      # otherwisek tries to get an existing token from the token store,
      # otherwise requests one through basic auth,
      # otherwise raises an exception.
      #
      def token
        return @settings.token if @settings.token?

        token = token_store.load(token_store_key)
        return token if token

        return nil unless @settings.autologin

        token = V1.request_auth_token!(auth_connection)
        token_store.store(token_store_key, token)
        token
      end

      # The key to use to store a token, uses the format host:database:username
      #
      def token_store_key
        @token_store_key ||=
          begin
            # Strip the host part to just the hostname (i.e. no scheme or port)
            host = @settings.host!
            host = URI(host).hostname if host =~ /\Ahttps?:\/\//
            identity_segment = if fmid_token = @settings.fmid_token
                                 require "digest"
                                 Digest::SHA256.hexdigest(fmid_token)
                               else
                                 @settings.username!
                               end
            "#{host}:#{@settings.database!}:#{identity_segment}"
          end
      end

      def token_store_option
        @settings.token_store || FmRest.token_store
      end

      def auth_connection
        # NOTE: this is purposely not memoized so that settings can be
        # refreshed (since proc-based settings will not be automatically
        # re-eval'd, for example for fmid_token-based auth)
        V1.auth_connection(@settings)
      end
    end
  end
end
