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
                    :included_portals, :portal_params

      def initialize(*_args)
        super

        @limit_value = klass.default_limit

        if klass.default_sort.present?
          @sort_params = Array.wrap(klass.default_sort).map { |s| normalize_sort_param(s) }
        end

        @query_params = []

        @included_portals = nil
        @portal_params = {}
      end

      # @param value_or_hash [Integer, Hash] the limit value for this layout,
      #   or a hash with limits for the layout's portals
      # @example
      #   Person.limit(10) # Set layout limit
      #   Person.limit(children: 10) # Set portal limit
      # @return [FmRest::Spyke::Relation] a new relation with the limits
      #   applied
      def limit(value_or_hash)
        with_clone do |r|
          if value_or_hash.respond_to?(:each)
            r.set_portal_params(value_or_hash, :limit)
          else
            r.limit_value = value_or_hash
          end
        end
      end

      # @param value_or_hash [Integer, Hash] the offset value for this layout,
      #   or a hash with offsets for the layout's portals
      # @example
      #   Person.offset(10) # Set layout offset
      #   Person.offset(children: 10) # Set portal offset
      # @return [FmRest::Spyke::Relation] a new relation with the offsets
      #   applied
      def offset(value_or_hash)
        with_clone do |r|
          if value_or_hash.respond_to?(:each)
            r.set_portal_params(value_or_hash, :offset)
          else
            r.offset_value = value_or_hash
          end
        end
      end

      # Allows sort params given in either hash format (using FM Data API's
      # format), or as a symbol, in which case the of the attribute must match
      # a known mapped attribute, optionally suffixed with `!` or `__desc` to
      # signify it should use descending order.
      #
      # @param args [Array<Symbol, Hash>] the names of attributes to sort by with
      #   optional `!` or `__desc` suffix, or a hash of options as expected by
      #   the FM Data API
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

      # Sets the portals to include with each record in the response.
      #
      # @param args [Array<Symbol, String>, true, false] the names of portals to
      #   include, or `false` to request no portals
      # @example
      #   Person.portal(:relatives, :pets)
      #   Person.portal(false) # Disables portals
      #   Person.portal(true) # Enables portals (includes all)
      # @return [FmRest::Spyke::Relation] a new relation with the portal
      #   options applied
      def portal(*args)
        raise ArgumentError, "Call `portal' with at least one argument" if args.empty?

        with_clone do |r|
          if args.length == 1 && args.first.eql?(true) || args.first.eql?(false)
            r.included_portals = args.first ? nil : []
          else
            r.included_portals ||= []
            r.included_portals += args.flatten.map { |p| normalize_portal_param(p) }
            r.included_portals.uniq!
          end
        end
      end
      alias includes portal
      alias portals portal

      # Same as calling `portal(true)`
      #
      # @return (see #portal)
      def with_all_portals
        portal(true)
      end

      # Same as calling `portal(false)`
      #
      # @return (see #portal)
      def without_portals
        portal(false)
      end

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

      protected

      def set_portal_params(params_hash, param)
        # Copy portal_params so we're not modifying the same hash as the parent
        # scope
        self.portal_params = portal_params.dup

        params_hash.each do |portal_name, value|
          # TODO: Use a hash like { portal_name: { param: value } } instead so
          # we can intelligently avoid including portal params for excluded
          # portals
          key = "#{param}.#{normalize_portal_param(portal_name)}"

          # Delete key if value is falsy
          if !value && portal_params.has_key?(key)
            portal_params.delete(key)
          else
            self.portal_params[key] = value
          end
        end
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

      def with_clone
        clone.tap do |relation|
          yield relation
        end
      end
    end
  end
end
