# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module Connection
        extend ActiveSupport::Concern

        included do
          class_attribute :fmrest_config, instance_writer: false, instance_predicate: false

          # Overrides the fmrest_config reader created by class_attribute so we
          # can default set the default at call time.
          #
          # This method gets overwriten in subclasses if self.fmrest_config= is
          # called.
          define_singleton_method(:fmrest_config) do
            FmRest.default_connection_settings
          end

          class_attribute :faraday_block, instance_accessor: false, instance_predicate: false
          class << self; private :faraday_block, :faraday_block=; end

          # FM Data API expects PATCH for updates (Spyke's default was PUT)
          self.callback_methods = { create: :post, update: :patch }.freeze
        end

        class_methods do
          def connection
            super || fmrest_connection
          end

          # Sets a block for injecting custom middleware into the Faraday
          # connection. Example usage:
          #
          #     class MyModel < FmRest::Spyke::Base
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

          def fmrest_connection
            @fmrest_connection ||=
              begin
                config = fmrest_config

                FmRest::V1.build_connection(config) do |conn|
                  faraday_block.call(conn) if faraday_block

                  # Pass the class to SpykeFormatter's initializer so it can have
                  # access to extra context defined in the model, e.g. a portal
                  # where name of the portal and the attributes prefix don't match
                  # and need to be specified as options to `portal`
                  conn.use FmRest::Spyke::SpykeFormatter, self

                  conn.use FmRest::V1::TypeCoercer, config

                  # FmRest::Spyke::JsonParse expects symbol keys
                  conn.response :json, parser_options: { symbolize_names: true }
                end
              end
          end
        end
      end
    end
  end
end
