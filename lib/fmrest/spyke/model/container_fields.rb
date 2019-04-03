# frozen_string_literal: true

require "fmrest/spyke/container_field"

module FmRest
  module Spyke
    module Model
      module ContainerFields
        extend ::ActiveSupport::Concern

        class_methods do
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

