# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module Auth
        extend ::ActiveSupport::Concern

        class_methods do
          # Logs out the database session for this model (and other models
          # using the same credentials).
          #
          # @raise [FmRest::V1::TokenSession::NoSessionTokenSet] if no session
          #   token was set (and no request is sent).
          def logout!
            connection.delete(FmRest::V1.session_path("dummy-token"))
          end

          # Logs out the database session for this model (and other models
          # using the same credentials). Unlike `logout!`, no exception is
          # raised in case of missing session token.
          #
          # @return [Boolean] Whether the logout request was sent (it's only
          #   sent if a session token was previously set)
          def logout
            logout!
            true
          rescue FmRest::V1::TokenSession::NoSessionTokenSet
            false
          end
        end
      end
    end
  end
end
