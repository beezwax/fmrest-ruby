# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module URI
        extend ::ActiveSupport::Concern

        class_methods do
          # Accessor for FM layout (helps with building the URI)
          #
          def layout(layout = nil)
            @layout = layout if layout
            @layout ||= model_name.name
          end

          # Spyke override -- Extends `uri` to default to FM Data's URI schema
          #
          def uri(uri_template = nil)
            if @uri.nil? && uri_template.nil?
              return FmRest::V1.record_path(layout) + "(/:#{primary_key})"
            end
            super
          end
        end
      end
    end
  end
end
