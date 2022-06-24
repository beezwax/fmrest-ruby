# frozen_string_literal: true

require "fmrest"

module Rails
  module FmRest
    class Railtie < Rails::Railtie
      # Mapping of rescued exceptions to HTTP responses
      #
      # @example
      #   railtie.rescue_responses
      #
      # @ return [Hash] rescued responses
      def self.rescue_responses
        {
          "FmRest::APIError::RecordMissingError"     => :not_found,
          "FmRest::APIError::NoMatchingRecordsError" => :not_found,
          "FmRest::APIError::ValidationError"        => :unprocessable_entity,
          "FmRest::Spyke::ValidationError"           => :unprocessable_entity,
        }
      end

      if config.action_dispatch.rescue_responses
        config.action_dispatch.rescue_responses.merge!(rescue_responses)
      end

      initializer "fmrest.load_config" do
        ::FmRest.default_connection_settings = Rails.application.config_for("fmrest")
      end
    end
  end
end
