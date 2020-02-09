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


          def request(*args)
            super.tap do |r|
              Thread.current[last_request_metadata_key] = r.metadata
            end
          end

          def last_request_metadata
            Thread.current[last_request_metadata_key]
          end

          private

          def last_request_metadata_key
            "#{to_s}.last_request_metadata"
          end
        end
      end
    end
  end
end
