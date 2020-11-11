# frozen_string_literal: true

require "fmrest/spyke/container_field"

module FmRest
  module Spyke
    module Model
      # This module adds support for container fields.
      #
      module ContainerFields
        extend ::ActiveSupport::Concern

        class_methods do
          # Defines a container field on the model.
          #
          # @param name [Symbol] the name of the container field
          #
          # @option options [String] :field_name (nil) the name of the container
          #   field in the FileMaker layout (only needed if it doesn't match
          #   the name given)
          #
          # @example
          #   class Honeybee < FmRest::Spyke::Base
          #     container :photo, field_name: "Beehive Photo ID"
          #   end
          #
          def container(name, options = {})
            field_name = options[:field_name] || name

            define_method(name) do
              @container_fields ||= {}
              @container_fields[name.to_sym] ||= ContainerField.new(self, field_name)
            end
          end
        end
      end
    end
  end
end

