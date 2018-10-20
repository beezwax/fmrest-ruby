require "fmdata/spyke/model/connection"
require "fmdata/spyke/model/uri"
require "fmdata/spyke/model/attributes"
require "fmdata/spyke/model/portals"

module FmData
  module Spyke
    module Model
      extend ::ActiveSupport::Concern

      include Connection
      include Uri
      include Attributes
      include Portals

      CLASS_FIND_RE = %r(`find').freeze

      included do
        attr_accessor :mod_id
      end

      class_methods do
        # Can find single record through record_path with id
        # If finding by conditions, need to use find_path with query and limit
        #
        def where(condition)
          is_find = caller.first.match(CLASS_FIND_RE)

          if is_find
            @uri = FmData::V1.record_path(layout) + "(/:id)"
            results = super(condition)
          else
            # Want unlimited, but limit must be an int greater than 0
            params = {
              query: [condition],
              limit: '9999999'
            }
            @uri = FmData::V1.find_path(layout)
            results = super(params).post
          end

          @uri = nil
          results
        end
      end
    end
  end
end
