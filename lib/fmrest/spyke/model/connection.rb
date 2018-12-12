module FmData
  module Spyke
    module Model
      module Connection
        extend ::ActiveSupport::Concern

        included do
          class_attribute :fmdata_config, instance_accessor: false, instance_predicate: false

          class_attribute :faraday_block, instance_accessor: false, instance_predicate: false
          class << self; private :faraday_block, :faraday_block=; end

          # FM Data API expects PATCH for updates (Spyke's default was PUT)
          self.callback_methods = { create: :post, update: :patch }.freeze
        end

        class_methods do
          def connection
            super || fmdata_connection
          end

          # Sets a block for injecting custom middleware into the Faraday
          # connection. Example usage:
          #
          #     class MyModel < FmData::Spyke::Base
          #       faraday do |conn|
          #         # Set up a custom logger for the model
          #         conn.response :logger, MyApp.logger, bodies: true
          #       end
          #     end
          #
          def faraday(&block)
            self.faraday_block = block
          end

          private

          def fmdata_connection
            @fmdata_connection ||= FmData::V1.build_connection(fmdata_config) do |conn|
              faraday_block.call(conn) if faraday_block

              # Pass the class to JsonParser's initializer so it can have
              # access to extra context defined in the model, e.g. a portal
              # where name of the portal and the attributes prefix don't match
              # and need to be specified as options to `portal`
              conn.use FmData::Spyke::JsonParser, self
            end
          end
        end
      end
    end
  end
end
