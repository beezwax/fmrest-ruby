# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      # This mixin allows rescuing from errors raised during HTTP requests,
      # with optional retry (useful for solving expired auth). This is based
      # off ActiveSupport::Rescuable, with minimal added functionality. Its
      # usage is analogous to `rescue_from` in Rails' controllers.
      #
      # Example usage:
      #
      #   MyLayout < FmRest::Layout
      #     # Mix-in module
      #     include FmRest::Spyke::Model::Rescuable
      #
      #     # Define an error handler
      #     rescue_from FmRest::APIError::SomeError, with: :report_error
      #
      #     # Define block-based error handler
      #     rescue_from FmRest::APIError::SomeOtherError, with: -> { ... }
      #
      #     private
      #
      #     def report_error(exception)
      #       ErrorNotifier.notify(exception)
      #     ene
      #   end
      #
      # This module also extends upon ActiveSupport's implementation by
      # allowing to request a retry of the failed request, which can be useful
      # in situations where an auth token has expired and credentials need to
      # be manually reset.
      #
      # To request a retry use `throw :retry` within the handler method.
      #
      # Finally, since it's the most common use case, there's a shorthand
      # method for handling Data API authentication errors:
      #
      #   rescue_account_error with: -> { CredentialsManager.refresh_credentials }
      #
      # This method will always issue a retry.
      #
      module Rescuable
        extend ::ActiveSupport::Concern
        include ::ActiveSupport::Rescuable

        class_methods do
          def request(*args)
            begin
              super
            rescue => e
              catch :retry do
                rescue_with_handler(e) || raise
                return
              end
              super
            end
          end

          def rescue_account_error(with: nil)
            rescue_from(APIError::AccountError, with: with) do
              yield
              throw :retry
            end
          end
        end
      end
    end
  end
end
