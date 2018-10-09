module FmData
  module Spyke
    module Model
      module Connection
        extend ::ActiveSupport::Concern

        included do
          class_attribute :fmdata_config, instance_accessor: false

          # FM Data API expects PATCH for updates (Spyke's default was PUT)
          self.callback_methods = { create: :post, update: :patch }.freeze
        end

        class_methods do
          def connection
            super || fmdata_connection
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
end
