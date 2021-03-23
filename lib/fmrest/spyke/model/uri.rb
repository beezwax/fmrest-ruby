# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module URI
        extend ::ActiveSupport::Concern

        included do
          # Make the layout setting inheritable
          class_attribute :_layout, instance_predicate: false

          class << self
            protected :_layout
          end
        end

        class_methods do
          # Accessor for FM layout (user for building request URIs).
          #
          # @param layout [String] The FM layout to connect this class to
          #
          # @return [String] The current layout if manually set, or the name of
          #   the class otherwise
          #
          def layout(layout = nil)
            self._layout = layout.dup.to_s.freeze if layout
            self._layout || model_name.name
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
