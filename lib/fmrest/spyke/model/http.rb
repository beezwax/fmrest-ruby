# frozen_string_literal: true

require "fmrest/spyke/relation"

module FmRest
  module Spyke
    module Model
      module Http
        extend ::ActiveSupport::Concern

        class_methods do

          # Override Spyke's request method to keep a thread-local copy of the
          # last request's metadata, so that we can access things like script
          # execution results after a save, etc.


          # Spyke overwrite
          def request(*args)
            super.tap do |r|
              Thread.current[last_request_metadata_key] = r.metadata
            end
          end

          def last_request_metadata(key: last_request_metadata_key)
            Thread.current[key]
          end

          private

          def last_request_metadata_key
            "#{to_s}.last_request_metadata"
          end
        end
      end

      # Spyke overwrite
      def uri
        ::Spyke::Path.new(@uri_template, fmrest_uri_attributes) if @uri_template
      end

      private

      # Spyke overwrite
      def resolve_path_from_action(action)
        case action
        when Symbol then uri.join(action)
        when String then ::Spyke::Path.new(action, fmrest_uri_attributes)
        else uri
        end
      end

      def fmrest_uri_attributes
        persisted? ? { __record_id: record_id } : attributes.slice(:__record_id)
      end
    end
  end
end
