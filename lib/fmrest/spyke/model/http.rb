# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module Http
        extend ::ActiveSupport::Concern

        class_methods do

          # Override Spyke's request method to keep a thread-local copy of the
          # last request's metadata, so that we can access things like script
          # execution results after a save, etc.


          # Spyke override -- Keeps metadata in thread-local class variable.
          #
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

      # Spyke override -- Uses `__record_id` for building the record URI.
      #
      def uri
        ::Spyke::Path.new(@uri_template, fmrest_uri_attributes) if @uri_template
      end

      private

      # Spyke override (private) -- Use `__record_id` instead of `id`
      #
      def resolve_path_from_action(action)
        case action
        when Symbol then uri.join(action)
        when String then ::Spyke::Path.new(action, fmrest_uri_attributes)
        else uri
        end
      end

      def fmrest_uri_attributes
        if persisted?
          { __record_id: __record_id }
        else
          # NOTE: it seems silly to be calling attributes.slice(:__record_id)
          # when the record is supposed to not have a record_id set (since
          # persisted? is false here), but it makes sense in the context of how
          # Spyke works:
          #
          # When calling Model.find(id), Spyke will internally create a scope
          # with .where(primary_key => id) and call .find_one on it. Then,
          # somewhere down the line Spyke creates a new empty instance of the
          # current model class to get its .uri property (the one we're
          # partially building through this method and which contains these URI
          # attributes). When initializing a record Spyke first forcefully
          # assigns the .where()-set attributes from the current scope onto
          # that instance's attributes hash, which then leads us right here,
          # where we might have __record_id assigned as a scope attribute:
          attributes.slice(:__record_id)
        end
      end
    end
  end
end
