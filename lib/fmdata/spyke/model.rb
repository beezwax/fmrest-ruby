module FmData
  module Spyke
    module Model
      extend ::ActiveSupport::Concern

      included do
        attr_accessor :mod_id

        class_attribute :fmdata_config, instance_accessor: false

        # FM Data API expects PATCH for updates (Spyke's default was PUT)
        self.callback_methods = { create: :post, update: :patch }.freeze
      end

      class_methods do
        def connection
          super || fmdata_connection
        end

        # Accessor for FM layout
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

        # Extend attributes to support the mapped version
        #
        def attributes(*attr)
          if attr.length == 1 && attr.first.kind_of?(Hash)
            mapped_attributes(attr.first)
          else
            super
          end
        end

        # Similar to Spyke::Base.attributes, but allows defining attribute
        # methods that map to JSON attributes with different names.
        #
        # Example:
        #
        #   class Person < Spyke::Base
        #     include FmData::Spyke::Model
        #
        #     mapped_attributes first_name: "FstName", last_name: "LstName"
        #   end
        #
        #   p = Person.new
        #   p.first_name = "Jojo"
        #   p.attributes # => { "FstName" => "Jojo" }
        #
        def mapped_attributes(attr_map)
          unless instance_variable_defined?(:@fmdata_instance_method_container)
            @fmdata_instance_method_container = Module.new
            include @fmdata_instance_method_container
          end

          @fmdata_instance_method_container.module_eval do
            attr_map.each do |from, to|
              define_method(from) do
                attribute(to)
              end

              define_method(:"#{from}=") do |value|
                set_attribute(to, value)
              end
            end
          end
        end

        private

        def fmdata_connection
          @fmdata_connection ||= FmData::V1.build_connection(fmdata_config) do |conn|
            conn.use FmData::Spyke::JsonParser
          end
        end
      end

      # Override to_params to return FM Data API's expected
      # format
      #
      def to_params
        params = { fieldData: params_not_embedded_in_url }
        params[:modId] = mod_id if mod_id
        params
      end
    end
  end
end
