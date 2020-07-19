# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module Connection
        extend ActiveSupport::Concern

        included do
          class_attribute :faraday_block, instance_accessor: false, instance_predicate: false
          class << self; private :faraday_block, :faraday_block=; end

          # FM Data API expects PATCH for updates (Spyke's default is PUT)
          self.callback_methods = { create: :post, update: :patch }.freeze
        end

        class_methods do
          def fmrest_config
            if fmrest_config_override
              return FmRest.default_connection_settings.merge(fmrest_config_override, skip_validation: true)
            end

            FmRest.default_connection_settings
          end

          # Behaves similar to ActiveSupport's class_attribute, redefining the
          # reader method so it can be inherited and overwritten in subclasses
          #
          def fmrest_config=(settings)
            settings = ConnectionSettings.new(settings, skip_validation: true)

            redefine_singleton_method(:fmrest_config) do
              return settings.merge(fmrest_config_override, skip_validation: true) if fmrest_config_override
              settings
            end
          end

          # Allows overwriting some connection settings in a thread-local
          # manner. Useful in the use case where you want to connect to the
          # same database using different accounts (e.g. credentials provided
          # by users in a web app context)
          #
          def fmrest_config_override=(settings)
            Thread.current[fmrest_config_override_key] = settings
          end

          def fmrest_config_override
            Thread.current[fmrest_config_override_key] || begin
              superclass.fmrest_config_override
            rescue NoMethodError
              nil
            end
          end

          def clear_fmrest_config_override
            Thread.current[fmrest_config_override_key] = nil
          end

          def with_override(settings, &block)
            Fiber.new do
              begin
                self.fmrest_config_override = settings
                yield
              ensure
                self.clear_fmrest_config_override
              end
            end.resume
          end

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
            # NOTE: this method is intentionally unmemoized to prevent multiple
            # threads using the same connection (whether that would be a real
            # problem is not clear, but https://github.com/balvig/spyke/pull/63
            # suggests it might).
            #
            # Instead, each call will create a new connection. This could
            # probably be memoized with thread-local variables, but the
            # memoization would also need to be invalidated any time
            # .fmrest_config_override= is used on this or any parent class.

            config = ConnectionSettings.wrap(fmrest_config)

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

          def fmrest_config_override_key
            :"#{object_id}.fmrest_config_override"
          end
        end

        def fmrest_config
          self.class.fmrest_config
        end
      end
    end
  end
end
