require "fmdata/spyke/portal"

module FmData
  module Spyke
    module Model
      module Associations
        extend ::ActiveSupport::Concern

        included do
          # Keep track of portal options by their FM keys as we could need it
          # to parse the portalData JSON in JsonParser
          class_attribute :portal_options, instance_accessor: false,
                                           default:           {}.freeze

          class << self; private :portal_options=; end
        end

        class_methods do
          # Based on +has_many+, but creates a special Portal association
          # instead.
          #
          # Custom options:
          #
          # * <tt>:portal_key</tt> - The key used for the portal in the FM Data JSON portalData.
          # * <tt>:attribute_prefix</tt> - The prefix used for portal attributes in the FM Data JSON.
          #
          # Example:
          #
          #   has_portal :jobs, portal_key: "JobsTable", attribute_prefix: "Job"
          #
          def has_portal(name, options = {})
            create_association(name, Portal, options)

            # Store options for JsonParser to use if needed
            portal_key = options[:portal_key] || name
            self.portal_options = portal_options.merge(portal_key.to_s => options.dup).freeze

            define_method "#{name.to_s.singularize}_ids" do
              association(name).map(&:id)
            end
          end
        end

        # Override Spyke's association reader to keep a cache of loaded
        # portals. Spyke's default behavior is to reload the association
        # each time.
        #
        def association(name)
          @loaded_portals ||= {}

          if @loaded_portals.has_key?(name.to_sym)
            return @loaded_portals[name.to_sym]
          end

          super.tap do |assoc|
            next unless assoc.kind_of?(FmData::Spyke::Portal)
            @loaded_portals[name.to_sym] = assoc
          end
        end

        def reload
          super.tap { @loaded_portals = nil }
        end

        def portals
          self.class.associations.each_with_object([]) do |(key, _), portals|
            candidate = association(key)
            next unless candidate.kind_of?(FmData::Spyke::Portal)
            portals << candidate
          end
        end
      end
    end
  end
end

