# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module Rescuable
        extend ::ActiveSupport::Concern

        include ::ActiveSupport::Rescuable

        class_methods do
          def request(*args)
            begin
              super
            rescue => e
              rescue_with_handler(e) || raise
            end
          end

          def rescue_account_error(with: nil, &block)
            rescue_from APIError::AccountError, with: with, &block
          end
        end
      end
    end
  end
end
