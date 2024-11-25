# frozen_string_literal: true

require "fmrest/spyke/relation"
require "fmrest/spyke/validation_error"

module FmRest
  module Spyke
    module Model
      # This module adds and extends various ORM features in Spyke models,
      # including custom query methods, remote script execution and
      # exception-raising persistence methods.
      #
      module Orm
        extend ::ActiveSupport::Concern

        included do
          # Allow overriding FM's default limit (by default it's 100)
          class_attribute :default_limit, instance_accessor: false, instance_predicate: false

          class_attribute :default_sort, instance_accessor: false, instance_predicate: false
        end

        class_methods do
          # Methods delegated to `FmRest::Spyke::Relation`
          delegate :limit, :offset, :sort, :order, :query, :match, :omit,
            :portal, :portals, :includes, :with_all_portals, :without_portals,
            :script, :find_one, :first, :any, :find_some, :find_in_batches,
            :find_each, :and, :or, to: :all

          # Spyke override -- Use FmRest's Relation instead of Spyke's vanilla
          # one
          #
          def all
            current_scope || Relation.new(self, uri: uri)
          end

          # Spyke override -- properly sets limit, offset and other options, as
          # well as using the appropriate HTTP method/URL depending on whether
          # there's a query present in the current scope.
          #
          # @option options [Boolean] :raise_on_no_matching_records whether to
          #   raise `APIError::NoMatchingRecordsError` when no records match (FM
          #   error 401). If not given it returns an empty resultset.
          #
          # @example
          #   Person.query(first_name: "Stefan").fetch # -> POST .../_find
          #
          def fetch(options = {})
            if current_scope.has_query?
              scope = extend_scope_with_fm_params(current_scope, prefixed: false)
              scope = extend_scope_with_query_params(scope)
              scope = scope.with(FmRest::V1::find_path(layout))
            else
              scope = extend_scope_with_fm_params(current_scope, prefixed: true)
            end

            previous, self.current_scope = current_scope, scope

            current_scope.has_query? ? scoped_request(:post) : super()

          # The DAPI returns a 401 "No records match the request" error when
          # nothing matches a _find request, so we need to catch it in order
          # to provide sane behavior (i.e. return an empty resultset)
          rescue FmRest::APIError::NoMatchingRecordsError => e
            raise e if options[:raise_on_no_matching_records]
            ::Spyke::Result.new({})
          rescue Relation::UnsatisfiableQuery
            ::Spyke::Result.new({})
          ensure
            self.current_scope = previous
          end

          # Exception-raising version of `#create`
          #
          # @param attributes [Hash] the attributes to initialize the
          #   record with
          #
          def create!(attributes = {})
            new(attributes).tap(&:save!)
          end

          private

          def extend_scope_with_query_params(scope)
            query_params = scope.query_params

            case FmRest::Spyke.on_unsatisifiable_query
            when :return_silent, 'return_silent', :return_warn, 'return_warn'
              query_params = scope.satisifiable_query_params
            end

            scope.where(query: query_params)
          end

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

            if scope.script_params.present?
              where_options.merge!(scope.script_params)
            end

            scope.where(where_options)
          end
        end

        # Spyke override -- Adds a number of features to original `#save`:
        #
        # * Validations
        # * Data API scripts execution
        # * Refresh of dirty attributes
        #
        # @option options [String] :script the name of a FileMaker script to execute
        #   upon saving
        # @option options [Boolean] :raise_validation_errors whether to raise an
        #   exception if validations fail
        #
        # @return [true] if saved successfully
        # @return [false] if validations or persistence failed
        #
        def save(options = {})
          callback = persisted? ? :update : :create

          return false unless perform_save_validations(callback, options)
          return false unless perform_save_persistence(callback, options)

          true
        end

        # Exception-raising version of `#save`.
        #
        # @option (see #save)
        #
        # @return [true] if saved successfully
        #
        # @raise if validations or presistence failed
        #
        def save!(options = {})
          save(options.merge(raise_validation_errors: true))
        end

        # Exception-raising version of `#update`.
        #
        # @param new_attributes [Hash] a hash of record attributes to update
        #   the record with
        #
        # @option (see #save)
        #
        def update!(new_attributes, options = {})
          self.attributes = new_attributes
          save!(options)
        end

        # Spyke override -- Adds support for Data API script execution.
        #
        # @option options [String] :script the name of a FileMaker script to execute
        #   upon deletion
        #
        def destroy(options = {})
          # For whatever reason the Data API wants the script params as query
          # string params for DELETE requests, making this more complicated
          # than it should be
          script_query_string =
            if options.has_key?(:script)
              "?" + Faraday::Utils.build_query(FmRest::V1.convert_script_params(options[:script]))
            else
              ""
            end

          self.attributes = delete(uri.to_s + script_query_string)
        end

        # (see #destroy)
        #
        # @option (see #destroy)
        #
        def reload(options = {})
          scope = self.class
          scope = scope.script(options[:script]) if options.has_key?(:script)
          reloaded = scope.find(__record_id)
          self.attributes = reloaded.attributes
          self.__mod_id = reloaded.mod_id
        end

        # ActiveModel 5+ implements this method, so we only need it if we're in
        # the older AM4
        if ActiveModel::VERSION::MAJOR == 4
          def validate!(context = nil)
            valid?(context) || raise_validation_error
          end
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

        # Overwrite ActiveModel's raise_validation_error to use our own class
        #
        def raise_validation_error # :doc:
          raise(ValidationError.new(self))
        end
      end
    end
  end
end
