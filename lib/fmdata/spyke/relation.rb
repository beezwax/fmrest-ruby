module FmData
  module Spyke
    class Relation < ::Spyke::Relation
      # We need to keep these separate from regular params because FM Data API
      # uses either _limit or limit (or _offset, etc.) depending on the type of
      # request, so we can't set the params until the last moment
      attr_accessor :limit_value
      attr_accessor :offset_value
      attr_accessor :sort_value

      def initialize(*_args)
        super
        @limit_value = klass.default_limit
        @sort_value = klass.default_sort
      end

      def limit(value)
        relation = clone
        relation.limit_value = value
        relation
      end

      def offset(value)
        relation = clone
        relation.offset_value = value
        relation
      end

      def sort(*args)
        # TODO: Provide a nicer API for sort
        relation = clone
        relation.sort_value = Array.wrap(args)
        relation
      end
      alias :order :sort

      def portal(*args)
        # TODO: Allow passing portal names as defined in the class
        where(portal: Array.wrap(args).flatten)
      end
      alias :includes :portal

      def query(*conditions)
        # TODO: Merge with previous query
        where(query: conditions)
      end
    end
  end
end
