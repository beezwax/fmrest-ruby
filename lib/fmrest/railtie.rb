# frozen_string_literal: true

require "fmrest"

module Rails
  module FmRest
    class Railtie < Rails::Railtie
      initializer "fmrest.load_config" do
        ::FmRest.default_connection_settings = Rails.application.config_for("fmrest")
      end
    end
  end
end
