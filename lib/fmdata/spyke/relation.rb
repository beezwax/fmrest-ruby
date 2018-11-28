module FmData
  module Spyke
    class Relation < ::Spyke::Relation
      # We need to keep these separate from regular params because FM Data API
      # uses either limit or _limit (or _offset, etc.) depending on the type of
      # request, so we can't set the params until the last moment
      attr_accessor :limit_value
      attr_accessor :offset_value
      attr_accessor :sort_params
      attr_accessor :query_params

      def initialize(*_args)
        super
        @limit_value = klass.default_limit
        @sort_params = klass.default_sort
        @query_params = []
      end

      def limit(value)
        with_clone { |r| r.limit_value = value }
      end

      def offset(value)
        with_clone { |r| r.offset_value = value }
      end

      def sort(*args)
        # TODO: Provide a nicer API for sort
        with_clone { |r| r.sort_params = Array.wrap(args) }
      end
      alias :order :sort

      def portal(*args)
        # TODO: Allow passing portal names as defined in the class
        where(portal: args.flatten)
      end
      alias :includes :portal

      def query(*params)
        with_clone do |r|
          r.query_params += params.flatten.map { |p| normalize_query_params(p) }
        end
      end

      def omit(params)
        query(params.merge(omit: true))
      end

      private

      def normalize_query_params(params)
        params.each_with_object({}) do |(k, v), normalized|
          if k == :omit || k == "omit"
            # FM Data API wants omit values as strings, e.g. "true" or "false"
            # rather than true/false
            normalized["omit"] = v.to_s
            next
          end

          if k.kind_of?(Symbol) && mapped_attributes.has_key?(k)
            normalized[mapped_attributes[k].to_s] = v
          else
            normalized[k.to_s] = v
          end
        end
      end

      def with_clone
        clone.tap do |relation|
          yield relation
        end
      end
    end
  end
end
