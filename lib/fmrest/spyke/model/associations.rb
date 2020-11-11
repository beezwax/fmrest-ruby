# frozen_string_literal: true

require "fmrest/spyke/portal"

module FmRest
  module Spyke
    module Model
      # This module adds portal support to Spyke models.
      #
      module Associations
        extend ::ActiveSupport::Concern

        included do
          # Keep track of portal options by their FM keys as we could need it
          # to parse the portalData JSON in SpykeFormatter
          class_attribute :portal_options, instance_accessor: false, instance_predicate: false

          # class_attribute supports a :default option since ActiveSupport 5.2,
          # but we want to support previous versions too so we set the default
          # manually instead
          self.portal_options = {}.freeze

          class << self; private :portal_options=; end
        end

        class_methods do
          # Based on `has_many`, but creates a special Portal association
          # instead.
          #
          # @option :portal_key [String] The key used for the portal in the FM
          #   Data JSON portalData
          # @option :attribute_prefix [String] The prefix used for portal
          #   attributes in the FM Data JSON
          #
          # @example
          #   class Person < FmRest::Spyke::Base
          #     has_portal :jobs, portal_key: "JobsTable", attribute_prefix: "Job"
          #   end
          #
          def has_portal(name, options = {})
            create_association(name, Portal, options)

            # Store options for SpykeFormatter to use if needed
            portal_key = options[:portal_key] || name
            self.portal_options = portal_options.merge(portal_key.to_s => options.dup.merge(name: name.to_s)).freeze

            define_method "#{name.to_s.singularize}_ids" do
              association(name).map(&:id)
            end
          end
        end

        # Spyke override -- Keep a cache of loaded portals. Spyke's default
        # behavior is to reload the association each time.
        #
        def association(name)
          @loaded_portals ||= {}

          if @loaded_portals.has_key?(name.to_sym)
            return @loaded_portals[name.to_sym]
          end

          super.tap do |assoc|
            next unless assoc.kind_of?(FmRest::Spyke::Portal)
            @loaded_portals[name.to_sym] = assoc
          end
        end

        # Spyke override -- Add portals awareness
        #
        def reload(*_)
          super.tap { @loaded_portals = nil }
        end

        def portals
          self.class.associations.each_with_object([]) do |(key, _), portals|
            candidate = association(key)
            next unless candidate.kind_of?(FmRest::Spyke::Portal)
            portals << candidate
          end
        end
      end
    end
  end
end

