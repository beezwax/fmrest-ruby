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

        if klass.default_sort.present?
          @sort_params = Array.wrap(klass.default_sort).map { |s| normalize_sort_param(s) }
        end

        @query_params = []
      end

      def has_query?
        query_params.present?
      end

      def limit(value)
        with_clone { |r| r.limit_value = value }
      end

      def offset(value)
        with_clone { |r| r.offset_value = value }
      end

      # Allows sort params given in either hash format (using FM Data API's
      # format), or as a symbol, in which case the of the attribute must match
      # a known mapped attribute, optionally suffixed with ! or __desc[end] to
      # signify it should use descending order.
      #
      # E.g.
      #
      #     Person.sort(:first_name, :age!)
      #     Person.sort(:first_name, :age__desc)
      #     Person.sort(:first_name, :age__descend)
      #     Person.sort({ fieldName: "FirstName" }, { fieldName: "Age", sortOrder: "descend" })
      #
      def sort(*args)
        with_clone do |r|
          r.sort_params = args.flatten.map { |s| normalize_sort_param(s) }
        end
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

      def normalize_sort_param(param)
        if param.kind_of?(Symbol) || param.kind_of?(String)
          _, attr, descend = param.to_s.match(/(.*?)(!|__desc(?:end))?\Z/).to_a

          unless field_name = klass.mapped_attributes[attr]
            raise "Unknown attribute `#{attr}` given to sort as :#{param}"
          end

          hash = { fieldName: field_name }
          hash[:sortOrder] = "descend" if descend
          return hash
        end

        # TODO: Sanitize sort hash param?
        param
      end

      def normalize_query_params(params)
        params.each_with_object({}) do |(k, v), normalized|
          if k == :omit || k == "omit"
            # FM Data API wants omit values as strings, e.g. "true" or "false"
            # rather than true/false
            normalized["omit"] = v.to_s
            next
          end

          if k.kind_of?(Symbol) && klass.mapped_attributes.has_key?(k)
            normalized[klass.mapped_attributes[k].to_s] = v
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
