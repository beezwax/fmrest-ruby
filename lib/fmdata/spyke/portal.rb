module FmData
  module Spyke
    # Extend Spyke's HasMany association with custom options
    #
    class Portal < ::Spyke::Associations::HasMany
      def initialize(*args)
        super

        # Portals are always embedded
        @options[:uri] = nil
      end

      private

      def embedded_data
        parent.attributes[portal_key]
      end

      def portal_key
        return @options[:portal_key] if @options[:portal_key]
        name
      end
    end
  end
end
