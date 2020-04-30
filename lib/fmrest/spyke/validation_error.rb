# frozen_string_literal: true

module FmRest
  module Spyke
    # ActiveModel 4 doesn't include a ValidationError class, which we want to
    # raise when model.validate! fails.
    #
    # In order to break the least amount of code that uses AM5+, while still
    # supporting AM4 we use this proxy class that inherits from
    # AM::ValidationError if it's there, or reimplements it otherwise
    if defined?(::ActiveModel::ValidationError)
      class ValidationError < ::ActiveModel::ValidationError; end
    else
      class ValidationError < StandardError
        attr_reader :model

        def initialize(model)
          @model = model
          errors = @model.errors.full_messages.join(", ")
          super("Invalid model: #{errors}")
        end
      end
    end
  end
end
