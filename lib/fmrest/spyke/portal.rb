# frozen_string_literal: true

module FmRest
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
        (@options[:portal_key] || name).to_s
      end

      def attribute_prefix
        (@options[:attribute_prefix] || portal_key).to_s
      end

      # Callback method, not meant to be used directly
      #
      def parent_changes_applied
        each(&:changes_applied)
      end

      def <<(*records)
        records.flatten.each { |r| add_to_parent(r) }
        self
      end
      alias_method :push, :<<
      alias_method :concat, :<<

      def _remove_marked_for_destruction
        find_some.reject!(&:marked_for_destruction?)
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

      # Spyke override
      #
      def add_to_parent(record)
        raise ArgumentError, "Expected an instance of #{klass}, got a #{record.class} instead" unless record.kind_of?(klass)
        find_some << record
        record.embedded_in_portal
        record
      end
    end
  end
end
