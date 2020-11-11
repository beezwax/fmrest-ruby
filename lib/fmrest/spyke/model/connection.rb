# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      # This module provides methods for configuring the Farday connection for
      # the model, as well as setting up the connection itself.
      #
      module Connection
        extend ActiveSupport::Concern

        included do
          class_attribute :faraday_block, instance_accessor: false, instance_predicate: false
          class << self; private :faraday_block, :faraday_block=; end

          # FM Data API expects PATCH for updates (Spyke uses PUT by default)
          self.callback_methods = { create: :post, update: :patch }.freeze
        end

        class_methods do
          def fmrest_config
            if fmrest_config_overlay
              return FmRest.default_connection_settings.merge(fmrest_config_overlay, skip_validation: true)
            end

            FmRest.default_connection_settings
          end

          # Sets the FileMaker connection settings for the model.
          #
          # Behaves similar to ActiveSupport's `class_attribute`, so it can be
          # inherited and safely overwritten in subclasses.
          #
          # @param settings [Hash] The settings hash
          #
          def fmrest_config=(settings)
            settings = ConnectionSettings.new(settings, skip_validation: true)

            redefine_singleton_method(:fmrest_config) do
              overlay = fmrest_config_overlay
              return settings.merge(overlay, skip_validation: true) if overlay
              settings
            end
          end

          # Allows overriding some connection settings in a thread-local
          # manner. Useful in the use case where you want to connect to the
          # same database using different accounts (e.g. credentials provided
          # by users in a web app context).
          #
          # @param (see #fmrest_config=)
          #
          def fmrest_config_overlay=(settings)
            Thread.current[fmrest_config_overlay_key] = settings
          end

          # @return [FmRest::ConnectionSettings] the connection settings
          #   overlay if any is in use
          #
          def fmrest_config_overlay
            Thread.current[fmrest_config_overlay_key] || begin
              superclass.fmrest_config_overlay
            rescue NoMethodError
              nil
            end
          end

          # Clears the connection settings overlay.
          #
          def clear_fmrest_config_overlay
            Thread.current[fmrest_config_overlay_key] = nil
          end

          # Runs a block of code in the context of the given connection
          # settings without affecting the connection settings outside said
          # block.
          #
          # @param (see #fmrest_config=)
          #
          # @example
          #   Honeybee.with_overlay(username: "...", password: "...") do
          #     Honeybee.query(...)
          #   end
          #
          def with_overlay(settings, &block)
            Fiber.new do
              begin
                self.fmrest_config_overlay = settings
                yield
              ensure
                self.clear_fmrest_config_overlay
              end
            end.resume
          end

          # Spyke override -- Defaults to `fmrest_connection`
          #
          def connection
            super || fmrest_connection
          end

          # Sets a block for injecting custom middleware into the Faraday
          # connection.
          #
          # @example
          #   class MyModel < FmRest::Spyke::Base
          #     faraday do |conn|
          #       # Set up a custom logger for the model
          #       conn.response :logger, MyApp.logger, bodies: true
          #     end
          #   end
          #
          def faraday(&block)
            self.faraday_block = block
          end

          private

          def fmrest_connection
            memoize = false

            # Don't memoize the connection if there's an overlay, since
            # overlays are thread-local and so should be the connection
            unless fmrest_config_overlay
              return @fmrest_connection if @fmrest_connection
              memoize = true
            end

            config = ConnectionSettings.wrap(fmrest_config)

            connection =
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

            @fmrest_connection = connection if memoize

            connection
          end

          def fmrest_config_overlay_key
            :"#{object_id}.fmrest_config_overlay"
          end
        end

        def fmrest_config
          self.class.fmrest_config
        end
      end
    end
  end
end
