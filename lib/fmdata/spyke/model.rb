module FmData
  module Spyke
    module Model
      extend ::ActiveSupport::Concern

      included do
        class_attribute :fmdata_config, instance_accessor: false
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
            return FmData::V1.record_path(fmdata_config.fetch(:database), layout) + "(/:id)"
          end

          super
        end

        private

        def fmdata_connection
          @fmdata_connection ||= FmData::V1.build_connection(fmdata_config) do |conn|
            conn.use FmData::Spyke::JsonParser
          end
        end
      end
    end
  end
end
