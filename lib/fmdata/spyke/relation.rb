module FmData
  module Spyke
    class Relation < ::Spyke::Relation
      def limit(limit)
        where(_limit: limit)
      end

      def offset(offset)
        where(_offset: offset)
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
