# frozen_string_literal: true

# This is capitalized differently (Fmrest vs FmRest) on purpose, so the
# generator can be found as "fmrest:config"
module Fmrest
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def create_model_file
        template "model.rb", "app/models/#{file_name}.rb"
      end
    end
  end
end
