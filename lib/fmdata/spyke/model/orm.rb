require "fmdata/spyke/relation"

module FmData
  module Spyke
    module Model
      module Orm
        extend ::ActiveSupport::Concern

        included do
          # Allow overriding FM's default limit (by default it's 100)
          class_attribute :default_limit, instance_accessor: false

          class_attribute :default_sort, instance_accessor: false
        end

        class_methods do
          delegate :limit, :offset, :sort, :query, to: :all

          def all
            # Use FmData's Relation insdead of Spyke's vanilla one
            current_scope || Relation.new(self, uri: uri)
          end

          # Extended fetch to allow properly setting limit, offset and other
          # options, as well as using the appropriate HTTP method/URL depending
          # on whether there's a query present in the current scope, e.g.:
          #
          #     Person.query(first_name: "Stefan").fetch # POST .../_find
          #
          def fetch
            if current_scope.has_query?
              scope = extend_scope_with_fm_params(current_scope, prefixed: false)
              scope = scope.where(query: scope.query_params)
              scope = scope.with(FmData::V1::find_path(layout))
            else
              scope = extend_scope_with_fm_params(current_scope, prefixed: true)
            end

            previous, self.current_scope = current_scope, scope
            current_scope.has_query? ? scoped_request(:post) : super
          ensure
            self.current_scope = previous
          end

          private

          def extend_scope_with_fm_params(scope, prefixed: false)
            prefix = prefixed ? "_" : nil

            where_options = {}

            where_options["#{prefix}limit"] = scope.limit_value if scope.limit_value
            where_options["#{prefix}offset"] = scope.offset_value if scope.offset_value

            if scope.sort_params.present? && scope.limit_value != 1
              where_options["#{prefix}sort"] =
                prefixed ? scope.sort_params.to_json : scope.sort_params
            end

            scope.where(where_options)
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
end
