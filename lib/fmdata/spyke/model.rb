require "fmdata/spyke/model/connection"
require "fmdata/spyke/model/uri"
require "fmdata/spyke/model/attributes"
require "fmdata/spyke/model/associations"
require "fmdata/spyke/relation"

module FmData
  module Spyke
    module Model
      extend ::ActiveSupport::Concern

      include Connection
      include Uri
      include Attributes
      include Associations

      #CLASS_FIND_RE = %r(`find').freeze

      included do
        attr_accessor :mod_id

        # Allow overriding FM's default limit of 100
        class_attribute :default_limit, instance_accessor: false
      end

      class_methods do
        # Can find single record through record_path with id
        # If finding by conditions, need to use find_path with query and limit
        #
        #def where(condition)
        #  is_find = caller.first.match(CLASS_FIND_RE)
        #  @uri = FmData::V1.record_path(layout) + "(/:id)"
        #  return super(condition) if is_find

        #  # Want unlimited, but limit must be an int greater than 0
        #  params = {
        #    query: [condition],
        #    limit: '9999999'
        #  }
        #  @uri = FmData::V1.find_path(layout)
        #  super(params).post
        #end

        delegate :limit, :offset, :sort, :query, to: :all

        # Override all to use FmData's Relation insdead of Spyke's vanilla one
        #
        def all
          current_scope || Relation.new(self, uri: uri)
        end

        # Provide an interface for FM Data API's _find endpoint
        #
        def search(*conditions)
          # TODO: Apply default limit
          scope = conditions.empty? ? all : query(*conditions)
          scope.with(FmData::V1::find_path(layout)).post
        end
      end

      # Ensure save returns true/false, following ActiveRecord's convention
      #
      def save(options = {})
        if options[:validate] == false || valid?
          super().present? # Failed save returns empty hash
        else
          false
        end
      end
    end
  end
end
