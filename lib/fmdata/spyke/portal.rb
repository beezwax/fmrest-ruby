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

      private

      # Spyke::Associations::HasMany#initialize calls primary_key to build the
      # default URI, which causes a NameError, so this is here just to prevent
      # that. We don't care what it returns as we override the URI with nil
      # anyway
      #
      def primary_key
      end

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
