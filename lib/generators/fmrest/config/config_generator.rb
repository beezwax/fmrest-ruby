# frozen_string_literal: true

# This is capitalized differently (Fmrest vs FmRest) on purpose, so the
# generator can be found as "fmrest:config"
module Fmrest
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def copy_config_file
        copy_file "fmrest.yml", "config/fmrest.yml"
      end

      def copy_initializer_file
        copy_file "fmrest_initializer.rb", "config/initializers/fmrest.rb"
      end
    end
  end
end
