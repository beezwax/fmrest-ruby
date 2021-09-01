# frozen_string_literal: true

require "fmrest/spyke/portal_builder"
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
          #
          # TODO: Replace this with options in PortalBuilder
          class_attribute :portal_options, instance_accessor: false, instance_predicate: false

          # class_attribute supports a :default option since ActiveSupport 5.2,
          # but we want to support previous versions too so we set the default
          # manually instead
          self.portal_options = {}.freeze

          class << self; private :portal_options=; end

          set_callback :save, :after, :remove_marked_for_destruction
        end

        class_methods do
          # Based on Spyke's `has_many`, but creates a special Portal
          # association instead.
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
            # This is analogous to Spyke's create_association method, but using
            # our custom builder instead
            self.associations = associations.merge(name => PortalBuilder.new(self, name, Portal, options))

            # Store options for SpykeFormatter to use if needed
            portal_key = options[:portal_key] || name
            self.portal_options = portal_options.merge(portal_key.to_s => options.dup.merge(name: name.to_s).freeze).freeze

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

        # @return [Array<FmRest::Spyke::Portal>] A collection of portal
        #   relations for the record
        #
        def portals
          self.class.associations.each_with_object([]) do |(key, _), portals|
            candidate = association(key)
            next unless candidate.kind_of?(FmRest::Spyke::Portal)
            portals << candidate
          end
        end

        # Signals that this record has been marked for being deleted next time
        # its parent record is saved (e.g. in a portal association)
        #
        # This method is named after ActiveRecord's namesake
        #
        def mark_for_destruction
          @marked_for_destruction = true
        end
        alias_method :mark_for_deletion, :mark_for_destruction

        def marked_for_destruction?
          !!@marked_for_destruction
        end
        alias_method :marked_for_deletion?, :marked_for_destruction?

        # Signals that this record has been embedded in a portal so we can make
        # sure to include it in the next update request
        #
        def embedded_in_portal
          @embedded_in_portal = true
        end

        def embedded_in_portal?
          !!@embedded_in_portal
        end

        # Override ActiveModel::Dirty's method to include clearing
        # of `@embedded_in_portal` and `@marked_for_destruction`
        #
        def changes_applied
          super
          @embedded_in_portal = nil
          @marked_for_destruction = nil
        end

        # Override ActiveModel::Dirty's method to include awareness
        # of `@embedded_in_portal`
        #
        def changed?
          super || embedded_in_portal?
        end

        # Takes care of updating the new portal record's recordIds and modIds.
        #
        # Called when saving a record with freshly added portal records, this
        # method is not meant to be called manually.
        #
        # @param [Hash] data The hash containing newPortalData from the DAPI
        #   response
        def __new_portal_record_info=(data)
          data.each do |d|
            table_name = d[:tableName]

            portal_new_records =
              portals.detect { |p| p.portal_key == table_name }.select { |r| !r.persisted? }

            # The DAPI provides only one recordId for the entire portal in the
            # newPortalRecordInfo object. This appears to be the recordId of
            # the last portal record created, so we assume all portal records
            # coming before it must have sequential recordIds up to the one we
            # do have.
            portal_new_records.reverse_each.with_index do |record, i|
              record.__record_id = d[:recordId].to_i - i

              # New records get a fresh modId
              record.__mod_id = 0
            end
          end
        end

        private

        def remove_marked_for_destruction
          portals.each(&:_remove_marked_for_destruction)
        end
      end
    end
  end
end
