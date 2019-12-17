# frozen_string_literal: true

require "fmrest/spyke/relation"

module FmRest
  module Spyke
    module Model
      module Orm
        extend ::ActiveSupport::Concern

        included do
          # Allow overriding FM's default limit (by default it's 100)
          class_attribute :default_limit, instance_accessor: false, instance_predicate: false

          class_attribute :default_sort, instance_accessor: false, instance_predicate: false

          # Whether to raise an FmRest::APIError::NoMatchingRecordsError when a
          # _find request has no results
          class_attribute :raise_on_no_matching_records, instance_accessor: false, instance_predicate: false
        end

        class_methods do
          # Methods delegated to FmRest::Spyke::Relation
          delegate :limit, :offset, :sort, :order, :query, :omit, :portal,
                   :portals, :includes, :with_all_portals, :without_portals,
                   to: :all

          def all
            # Use FmRest's Relation insdead of Spyke's vanilla one
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
              scope = scope.with(FmRest::V1::find_path(layout))
            else
              scope = extend_scope_with_fm_params(current_scope, prefixed: true)
            end

            previous, self.current_scope = current_scope, scope

            # The DAPI returns a 401 "No records match the request" error when
            # nothing matches a _find request, so we need to catch it in order
            # to provide sane behavior (i.e. return an empty resultset)
            begin
              current_scope.has_query? ? scoped_request(:post) : super
            rescue FmRest::APIError::NoMatchingRecordsError => e
              raise e if raise_on_no_matching_records
              ::Spyke::Result.new({})
            end
          ensure
            self.current_scope = previous
          end

          # API-error-raising version of #create
          #
          def create!(attributes = {})
            new(attributes).tap(&:save!)
          end

          def execute_script(script_name, params: {})
            request(:get, FmRest::V1::script_path(layout, script_name), params)
          end

          private

          def extend_scope_with_fm_params(scope, prefixed: false)
            prefix = prefixed ? "_" : nil

            where_options = {}

            where_options["#{prefix}limit"] = scope.limit_value if scope.limit_value
            where_options["#{prefix}offset"] = scope.offset_value if scope.offset_value

            if scope.sort_params.present?
              where_options["#{prefix}sort"] =
                prefixed ? scope.sort_params.to_json : scope.sort_params
            end

            unless scope.included_portals.nil?
              where_options["portal"] =
                prefixed ? scope.included_portals.to_json : scope.included_portals
            end

            if scope.portal_params.present?
              scope.portal_params.each do |portal_param, value|
                where_options["#{prefix}#{portal_param}"] = value
              end
            end

            scope.where(where_options)
          end
        end

        # Completely override Spyke's save to provide a number of features:
        #
        # * Validations
        # * Data API scripts execution
        # * Refresh of dirty attributes
        #
        def save(options = {})
          callback = persisted? ? :update : :create

          return false unless perform_save_validations(callback, options)
          return false unless perform_save_persistence(callback, options)

          true
        end

        def save!(options = {})
          save(options.merge(raise_validation_errors: true))
        end

        # API-error-raising version of #update
        #
        def update!(new_attributes)
          self.attributes = new_attributes
          save!
        end

        def reload
          reloaded = self.class.find(id)
          self.attributes = reloaded.attributes
          self.mod_id = reloaded.mod_id
        end

        private

        def perform_save_validations(context, options)
          return true if options[:validate] == false
          options[:raise_validation_errors] ? validate!(context) : validate(context)
        end

        def perform_save_persistence(callback, options)
          run_callbacks :save do
            run_callbacks(callback) do

              begin
                send self.class.method_for(callback), build_params_for_save(options)

              rescue APIError::ValidationError => e
                if options[:raise_validation_errors]
                  raise e
                else
                  return false
                end
              end

            end
          end

          true
        end

        def build_params_for_save(options)
          to_params.tap do |params|
            if options.has_key?(:script)
              params.merge!(FmRest::V1.convert_script_params(options[:script]))
            end
          end
        end
      end
    end
  end
end
