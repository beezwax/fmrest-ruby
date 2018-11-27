require "fmdata/spyke/relation"

module FmData
  module Spyke
    module Model
      module Orm
        extend ::ActiveSupport::Concern

        included do
          # Allow overriding FM's default limit of 100
          class_attribute :default_limit, instance_accessor: false
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
            scope = scope.where(limit: scope.limit_value) if scope.limit_value
            scope = scope.where(offset: scope.offset_value) if scope.offset_value
            scope.with(FmData::V1::find_path(layout)).post
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
