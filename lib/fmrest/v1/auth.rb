# frozen_string_literal: true

module FmRest
  module V1
    module Auth
      # Requests a token through basic auth
      #
      # @param connection [Faraday] the auth connection to use for
      #   the request
      # @return The token if successful
      # @return `false` if authentication failed
      def request_auth_token(connection = FmRest::V1.auth_connection)
        request_auth_token!(connection)
      rescue FmRest::APIError::AccountError
        false
      end

      # Requests a token through basic auth, raising
      # `FmRest::APIError::AccountError` if auth fails
      #
      # @param (see #request_auth_token)
      # @return The token if successful
      # @raise [FmRest::APIError::AccountError] if authentication failed
      def request_auth_token!(connection = FmRest.V1.auth_connection)
        resp = connection.post(V1.session_path)
        resp.body["response"]["token"]
      end
    end
  end
end
