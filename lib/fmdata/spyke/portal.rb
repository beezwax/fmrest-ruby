module FmData
  module Spyke
    # Extend Spyke's HasMany association with custom options
    #
    class Portal < ::Spyke::Associations::HasMany
      def initialize(*args)
        super

        # Portals are always embedded, so no special URI
        @options[:uri] = ""
      end

      def portal_key
        return @options[:portal_key] if @options[:portal_key]
        name
      end

      def attribute_prefix
        @options[:attribute_prefix] || portal_key
      end

      def parent_changes_applied
        each do |record|
          record.changes_applied
          # Saving portal data doesn't provide new modIds for the
          # portal records, so we clear them instead. We can still save
          # portal data without a mod_id (it's optional in FM Data API)
          record.mod_id = nil
        end
      end

      private

      # Spyke::Associations::HasMany#initialize calls primary_key to build the
      # default URI, which causes a NameError, so this is here just to prevent
      # that. We don't care what it returns as we override the URI with nil
      # anyway
      def primary_key; end

      # Make sure the association doesn't try to fetch records through URI
      def uri; nil; end

      def embedded_data
        parent.attributes[portal_key]
      end

      def add_to_parent(record)
        parent.attributes[portal_key] ||= []
        parent.attributes[portal_key] << record
        record
      end
    end
  end
end
