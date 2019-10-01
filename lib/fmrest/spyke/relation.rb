# frozen_string_literal: true

module FmRest
  module Spyke
    class Relation < ::Spyke::Relation
      SORT_PARAM_MATCHER = /(.*?)(!|__desc(?:end)?)?\Z/.freeze

      # NOTE: We need to keep limit, offset, sort, query and portal accessors
      # separate from regular params because FM Data API uses either "limit" or
      # "_limit" (or "_offset", etc.) as param keys depending on the type of
      # request, so we can't set the params until the last moment


      attr_accessor :limit_value, :offset_value, :sort_params, :query_params,
                    :portal_params, :portal_limit_or_offset_params

      def initialize(*_args)
        super

        @limit_value = klass.default_limit

        if klass.default_sort.present?
          @sort_params = Array.wrap(klass.default_sort).map { |s| normalize_sort_param(s) }
        end

        @query_params = []
        @portal_params = []
        @portal_limit_or_offset_params = {}
      end

      # @param value [Integer] the limit value
      # @return [FmRest::Spyke::Relation] a new relation with the limit applied
      def limit(value = 999, **portal_limits)
        r = with_clone { |r| r.limit_value = value }
        set_portal_limit_or_offset_params(r, portal_limits, type: :limit)
      end

      # @param value [Integer] the offset value
      # @return [FmRest::Spyke::Relation] a new relation with the offset
      #   applied
      def offset(value = 999, **portal_offsets)
        r = with_clone { |r| r.offset_value = value }
        set_portal_limit_or_offset_params(r, portal_offsets, type: :offset)
      end

      # Allows sort params given in either hash format (using FM Data API's
      # format), or as a symbol, in which case the of the attribute must match
      # a known mapped attribute, optionally suffixed with `!` or `__desc` to
      # signify it should use descending order.
      #
      # @param args [Array<Symbol, Hash>] the names of attributes to sort by with
      #   optional `!` or `__desc` suffix, or a hash of options as expected by
      #     the FM Data API
      # @example
      #   Person.sort(:first_name, :age!)
      #   Person.sort(:first_name, :age__desc)
      #   Person.sort(:first_name, :age__descend)
      #   Person.sort({ fieldName: "FirstName" }, { fieldName: "Age", sortOrder: "descend" })
      # @return [FmRest::Spyke::Relation] a new relation with the sort options
      #   applied
      def sort(*args)
        with_clone do |r|
          r.sort_params = args.flatten.map { |s| normalize_sort_param(s) }
        end
      end
      alias order sort

      def portal(*args)
        with_clone do |r|
          r.portal_params += args.flatten.map { |p| normalize_portal_param(p) }
          r.portal_params.uniq!
        end
      end
      alias includes portal

      def query(*params)
        with_clone do |r|
          r.query_params += params.flatten.map { |p| normalize_query_params(p) }
        end
      end

      def omit(params)
        query(params.merge(omit: true))
      end

      # @return [Boolean] whether a query was set on this relation
      def has_query?
        query_params.present?
      end

      # Finds a single instance of the model by forcing limit = 1
      #
      # @return [FmRest::Spyke::Base]
      def find_one
        return super if params[klass.primary_key].present?
        @find_one ||= klass.new_collection_from_result(limit(1).fetch).first
      rescue ::Spyke::ConnectionError => error
        fallback_or_reraise(error, default: nil)
      end

      private

      def normalize_sort_param(param)
        if param.kind_of?(Symbol) || param.kind_of?(String)
          _, attr, descend = param.to_s.match(SORT_PARAM_MATCHER).to_a

          unless field_name = klass.mapped_attributes[attr]
            raise ArgumentError, "Unknown attribute `#{attr}' given to sort as #{param.inspect}. If you want to use a custom sort pass a hash in the Data API format"
          end

          hash = { fieldName: field_name }
          hash[:sortOrder] = "descend" if descend
          return hash
        end

        # TODO: Sanitize sort hash param for FM Data API conformity?
        param
      end

      def normalize_portal_param(param)
        if param.kind_of?(Symbol)
          portal_key, = klass.portal_options.find { |_, opts| opts[:name].to_s == param.to_s }

          unless portal_key
            raise ArgumentError, "Unknown portal #{param.inspect}. If you want to include a portal not defined in the model pass it as a string instead"
          end

          return portal_key
        end

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

          # TODO: Raise ArgumentError if an attribute given as symbol isn't defiend
          if k.kind_of?(Symbol) && klass.mapped_attributes.has_key?(k)
            normalized[klass.mapped_attributes[k].to_s] = v
          else
            normalized[k.to_s] = v
          end
        end
      end

      def set_portal_limit_or_offset_params(r, limit_or_offset, type:)
        raise 'Type must be :limit or :offset' unless [:limit, :offset].include?(type)

        limit_or_offset.each do |portal_name, value|
          r.portal_limit_or_offset_params["#{type}.#{normalize_portal_param(portal_name)}"] = value
        end

        r
      end

      def with_clone
        clone.tap do |relation|
          yield relation
        end
      end
    end
  end
end
