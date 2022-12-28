# frozen_string_literal: true

module FmRest
  module Spyke
    class Relation < ::Spyke::Relation
      SORT_PARAM_MATCHER = /(.*?)(!|__desc(?:end)?)?\Z/.freeze

      class UnknownQueryKey < ArgumentError; end

      # NOTE: We need to keep limit, offset, sort, query and portal accessors
      # separate from regular params because FM Data API uses either "limit" or
      # "_limit" (or "_offset", etc.) as param keys depending on the type of
      # request, so we can't set the params until the last moment


      attr_accessor :limit_value, :offset_value, :sort_params, :query_params,
                    :or_flag, :included_portals, :portal_params, :script_params

      def initialize(*_args)
        super

        @limit_value = klass.default_limit

        if klass.default_sort.present?
          @sort_params = Array.wrap(klass.default_sort).map { |s| normalize_sort_param(s) }
        end

        @query_params = []

        @included_portals = nil
        @portal_params = {}
        @script_params = {}
      end

      # @param options [String, Array, Hash, nil, false] sets script params to
      #   execute in the next get or find request
      #
      # @example
      #   # Find records and run the script named "My script"
      #   Person.script("My script").find_some
      #
      #   # Find records and run the script named "My script" with param "the param"
      #   Person.script(["My script", "the param"]).find_some
      #
      #   # Find records and run a prerequest, presort and after (normal) script
      #   Person.script(after: "Script", prerequest: "Prereq script", presort: "Presort script").find_some
      #
      #   # Same as above, but passing parameters too
      #   Person.script(
      #     after:      ["After script", "the param"],
      #     prerequest: ["Prereq script", "the param"],
      #     presort: o  ["Presort script", "the param"]
      #   ).find_some
      #
      #   Person.script(nil).find_some # Disable script execution
      #   Person.script(false).find_some # Disable script execution
      #
      # @return [FmRest::Spyke::Relation] a new relation with the script
      #   options applied
      def script(options)
        with_clone do |r|
          if options.eql?(false) || options.eql?(nil)
            r.script_params = {}
          else
            r.script_params = script_params.merge(FmRest::V1.convert_script_params(options))
          end
        end
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

      # Sets conditions for a find request. Conditions must be given in
      # `{ field: condition }` format, where `condition` is normally a string
      # sent raw to the Data API server, so you can use FileMaker find
      # operators. You can also pass Ruby range or date/datetime objects for
      # condition values, and they'll be converted to the appropriate Data API
      # representation.
      #
      # Passing `omit: true` in a conditions set will negate all conditions in
      # that set.
      #
      # You can modify the way conditions are added (i.e. through logical AND
      # or OR) by pre-chaining `.or`. By default it adds conditions through
      # logical AND.
      #
      # Note that because of the way the Data API works, logical AND conditions
      # on a single field are not possible. Because of that, if you try to set
      # two AND conditions for the same field, the previously existing one will
      # be overwritten with the new condition.
      #
      # It is recommended that you learn how the Data API represents conditions
      # in its find requests (i.e. an array of JSON objects with conditions on
      # fields). This method internally uses that same representation, which
      # you can view by inspecting the resulting relations. Understanding that
      # representation will also make the limitations of this Ruby API clear.
      #
      # @example
      #   Person.query(name: "=Alice") # Simple query
      #   Person.query(age: (20..29)) # Query using a Ruby range
      #   Person.query(created_on: Date.today..Date.today-1)
      #   Person.query(name: "=Alice", age: ">20") # Query multiple fields (logical AND)
      #   Person.query(name: "=Alice").query(age: ">20") # Same effect as above example
      #   Person.query(name: "=Bob", omit: true) # Negate a query (i.e. find people not named Bob)
      #   Person.query(pets: { name: "=Snuggles" }) # Query portal fields
      #   Person.query({ name: "=Alice" }, { name: "=Bob" }) # Separate conditions through logical OR
      #   Person.query(name: "=Alice").or.query(name: "=Bob") # Same effect as above example
      # @return [FmRest::Spyke::Relation] a new relation with the given find
      #   conditions applied
      def query(*params)
        with_clone do |r|
          params = params.flatten.map { |p| normalize_query_params(p) }

          if r.or_flag || r.query_params.empty? # OR
            r.query_params += params
            r.or_flag = nil
          else # AND
            r.query_params = r
              .query_params
              .product(params)
              .map do |old_params, new_params|
                merge = old_params
                  .transform_values { |value| Set[value] }
                  .merge(
                    new_params.transform_values { |value| Set[value] }
                  ) { |_, old_value, new_value| old_value | new_value }

                if merge.values.any?(&:many?)
                  nil # reject params with different values for the same key
                else
                  merge.transform_values(&:first)
                end
              end.compact
          end
        end
      end

      # Similar to `.query`, but sets exact string match queries (i.e.
      # prefixes queries with ==) and escapes find operators in the given
      # queries using `FmRest.e`.
      #
      # @example
      #   Person.query(email: "bob@example.com") # Find exact email
      # @return [FmRest::Spyke::Relation] a new relation with the exact match
      #   conditions applied
      def match(*params)
        query(transform_query_values(params) { |v| "==#{FmRest::V1.escape_find_operators(v)}" })
      end

      # Negated version of `.query`, sets conditions to omit in a find request.
      #
      # This is the same as passing `omit: true` to `.query`.
      #
      # @return [FmRest::Spyke::Relation] a new relation with the given find
      #   conditions applied negated
      def omit(params)
        query(params.merge(omit: true))
      end

      # Signals that the next query conditions to be set (through `.query`,
      # `.match`, etc.) should be added as a logical OR relative to previously
      # set conditions (rather than the default AND).
      #
      # In practice this means the JSON query request will have a new
      # conditions object appended, e.g.:
      #
      # ```
      # {"query": [{"field": "condition"}, {"field": "OR-added condition"}]}
      # ```
      #
      # You can call this method with or without parameters. If parameters are
      # given they will be passed down to `.query` (and those conditions
      # immediately set), otherwise it just prepares the next
      # conditions-setting method to use OR.
      #
      # @example
      #   # Add conditions directly in .or call:
      #   Person.query(name: "=Alice").or(name: "=Bob")
      #   # Add exact match conditions through method chaining
      #   Person.match(email: "alice@example.com").or.match(email: "bob@example.com")
      def or(*params)
        clone = with_clone { |r| r.or_flag = true }
        params.empty? ? clone : clone.query(*params)
      end

      # @return [Boolean] whether a query was set on this relation
      def has_query?
        query_params.present?
      end

      # Finds a single instance of the model by forcing limit = 1, or simply
      # fetching the record by id if the primary key was set
      #
      # @option (see FmRest::Spyke::Model::ORM.fetch)
      #
      # @return [FmRest::Spyke::Base]
      def find_one(options = {})
        @find_one ||=
          if primary_key_set?
            without_collection_params { super() }
          else
            klass.new_collection_from_result(limit(1).fetch(options)).first
          end
      rescue ::Spyke::ConnectionError => error
        fallback_or_reraise(error, default: nil)
      end
      alias_method :first, :find_one
      alias_method :any, :find_one

      # Same as `#find_one`, but raises `APIError::NoMatchingRecordsError` when
      # no records match.
      # Equivalent to calling `find_one(raise_on_no_matching_records: true)`.
      #
      # @option (see FmRest::Spyke::Model::ORM.fetch)
      #
      # @return [FmRest::Spyke::Base]
      def find_one!(options = {})
        find_one(options.merge(raise_on_no_matching_records: true))
      end
      alias_method :first!, :find_one!

      # Yields each batch of records that was found by the find options.
      #
      # NOTE: By its nature, batch processing is subject to race conditions if
      # other processes are modifying the database
      #
      # @param batch_size [Integer] Specifies the size of the batch.
      # @return [Enumerator] if called without a block.
      def find_in_batches(batch_size: 1000)
        unless block_given?
          return to_enum(:find_in_batches, batch_size: batch_size) do
            total = limit(1).find_some.metadata.data_info.found_count
            (total - 1).div(batch_size) + 1
          end
        end

        offset = 1 # DAPI offset is 1-based

        loop do
          relation = offset(offset).limit(batch_size)

          records = relation.find_some

          yield records if records.length > 0

          break if records.length < batch_size

          # Save one iteration if the total is a multiple of batch_size
          if found_count = records.metadata.data_info && records.metadata.data_info.found_count
            break if found_count == (offset - 1) + batch_size
          end

          offset += batch_size
        end
      end

      # Looping through a collection of records from the database (using the
      # #all method, for example) is very inefficient since it will fetch and
      # instantiate all the objects at once.
      #
      # In that case, batch processing methods allow you to work with the
      # records in batches, thereby greatly reducing memory consumption and be
      # lighter on the Data API server.
      #
      # The find_each method uses #find_in_batches with a batch size of 1000
      # (or as specified by the :batch_size option).
      #
      # NOTE: By its nature, batch processing is subject to race conditions if
      # other processes are modifying the database
      #
      # @param (see #find_in_batches)
      # @example
      #   Person.find_each do |person|
      #     person.greet
      #   end
      #
      #   Person.query(name: "==Mitch").find_each do |person|
      #     person.say_hi
      #   end
      # @return (see #find_in_batches)
      def find_each(batch_size: 1000)
        unless block_given?
          return to_enum(:find_each, batch_size: batch_size) do
            limit(1).find_some.metadata.data_info.found_count
          end
        end

        find_in_batches(batch_size: batch_size) do |records|
          records.each { |r| yield r }
        end
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

          # Portal fields query (nested hash), e.g. { contact: { name: "Hutch" } }
          if v.kind_of?(Hash)
            if k.kind_of?(Symbol)
              portal_key, = klass.portal_options.find { |_, opts| opts[:name].to_s == k.to_s }

              if portal_key
                portal_model = klass.associations[k].klass

                portal_normalized = v.each_with_object({}) do |(pk, pv), h|
                  normalize_single_query_param_for_model(portal_model, pk, pv, h)
                end

                normalized.merge!(portal_normalized.transform_keys { |pf| "#{portal_key}::#{pf}" })
              else
                raise UnknownQueryKey, "No portal matches the query key `:#{k}` on #{klass.name}. If you are trying to use the literal string '#{k}' pass it as a string instead of a symbol."
              end
            else
              normalized.merge!(v.transform_keys { |pf| "#{k}::#{pf}" })
            end

            next
          end

          # Attribute query (scalar values), e.g. { name: "Hutch" }
          normalize_single_query_param_for_model(klass, k, v, normalized)
        end
      end

      def normalize_single_query_param_for_model(model, k, v, hash)
        if k.kind_of?(Symbol)
          if model.mapped_attributes.has_key?(k)
            hash[model.mapped_attributes[k].to_s] = format_query_condition(v)
          else
            raise UnknownQueryKey, "No attribute matches the query key `:#{k}` on #{model.name}. If you are trying to use the literal string '#{k}' pass it as a string instead of a symbol."
          end
        else
          hash[k.to_s] = format_query_condition(v)
        end
      end

      # Transforms various Ruby data types to FileMaker search condition
      # strings
      #
      def format_query_condition(condition)
        case condition
        when nil
          "=" # Search for empty field
        when Range
          format_range_condition(condition)
        when *FmRest::V1.datetime_classes
          FmRest::V1.convert_datetime_timezone(condition.to_datetime, klass.fmrest_config.timezone)
            .strftime(FmRest::V1::Dates::FM_DATETIME_FORMAT)
        when *FmRest::V1.date_classes
          condition.strftime(FmRest::V1::Dates::FM_DATE_FORMAT)
        else
          condition
        end
      end

      def format_range_condition(range)
        if range.first.kind_of?(Numeric)
          if range.first == Float::INFINITY || range.end == -Float::INFINITY
            raise ArgumentError, "Can't search for a range that begins at +Infinity or ends at -Infinity"
          elsif range.first == -Float::INFINITY
            if range.end == Float::INFINITY || range.end.nil?
              "*" # Search for non-empty field
            else
              range.exclude_end? ? "<#{range.end}" : "<=#{range.end}"
            end
          elsif range.end == Float::INFINITY || range.end.nil?
            ">=#{range.first}"
          elsif range.exclude_end? && range.last.respond_to?(:pred)
            "#{range.first}..#{range.last.pred}"
          else
            "#{range.first}..#{range.last}"
          end
        else
          "#{format_query_condition(range.first)}..#{format_query_condition(range.last)}"
        end
      end

      def transform_query_values(*params, &block)
        params.flatten.map do |p|
          p.transform_values do |v|
            v.kind_of?(Hash) ? v.transform_values(&block) : yield(v)
          end
        end
      end

      def primary_key_set?
        params[klass.primary_key].present?
      end

      def without_collection_params
        orig_values = limit_value, offset_value, sort_params, query_params
        self.limit_value = self.offset_value = self.sort_params = self.query_params = nil
        yield
      ensure
        self.limit_value, self.offset_value, self.sort_params, self.query_params = orig_values
      end

      def with_clone
        clone.tap do |relation|
          yield relation
        end
      end
    end
  end
end
