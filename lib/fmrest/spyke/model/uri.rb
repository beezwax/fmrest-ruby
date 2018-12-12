module FmData
  module Spyke
    module Model
      module Uri
        extend ::ActiveSupport::Concern

        class_methods do
          # Accessor for FM layout (helps with building the URI)
          #
          def layout(layout = nil)
            @layout = layout if layout
            @layout ||= model_name.name
          end

          # Extend uri acccessor to default to FM Data schema
          #
          def uri(uri_template = nil)
            if @uri.nil? && uri_template.nil?
              return FmData::V1.record_path(layout) + "(/:id)"
            end

            super
          end
        end
      end
    end
  end
end
