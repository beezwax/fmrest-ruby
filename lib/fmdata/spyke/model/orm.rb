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

          # Override all to use FmData's Relation insdead of Spyke's vanilla one
          #
          def all
            current_scope || Relation.new(self, uri: uri)
          end

          # Provide an interface for FM Data API's /_find endpoint
          #
          def search(*conditions)
            scope = conditions.empty? ? all : query(*conditions)
            scope = extend_scope_with_fm_params(scope)
            scope = scope.where(query: scope.query_params) if scope.query_params.present?
            scope.with(FmData::V1::find_path(layout)).post
          end

          # Extend fetch to allow properly setting limit, offset and other
          # options
          #
          def fetch
            scope = extend_scope_with_fm_params(current_scope, "_")

            begin
              previous, self.current_scope = current_scope, scope
              super
            ensure
              self.current_scope = previous
            end
          end

          private

          def extend_scope_with_fm_params(scope, prefix = "")
            scope = scope.where("#{prefix}limit": scope.limit_value) if current_scope.limit_value
            scope = scope.where("#{prefix}offset": scope.offset_value) if current_scope.offset_value
            scope = scope.where("#{prefix}sort": scope.sort_params) if current_scope.sort_params
            scope
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
