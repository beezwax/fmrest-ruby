module FmData
  module Spyke
    class Relation < ::Spyke::Relation
      attr_accessor :limit_value
      attr_accessor :offset_value

      def initialize(*_args)
        super
        @limit_value = klass.default_limit
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

      def sort(*sort)
        # TODO: Implement sort
      end

      def query(*conditions)
        # TODO: Merge with previous query
        where(query: conditions)
      end
    end
  end
end
