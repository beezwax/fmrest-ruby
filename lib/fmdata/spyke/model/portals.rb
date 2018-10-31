require "fmdata/spyke/portal"

module FmData
  module Spyke
    module Model
      module Portals
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
          #   portal :jobs, portal_key: "JobsTable", attribute_prefix: "Job"
          #
          def portal(name, options = {})
            create_association(name, Portal, options)

            # Store options for JsonParser to use if needed
            portal_key = options[:portal_key] || name
            self.portal_options = portal_options.merge(portal_key.to_s => options.dup).freeze

            define_method "#{name.to_s.singularize}_ids=" do |ids|
              attributes[name] = []
              ids.reject(&:blank?).each { |id| association(name).build(id: id) }
            end

            define_method "#{name.to_s.singularize}_ids" do
              association(name).map(&:id)
            end
          end
        end
      end
    end
  end
end

