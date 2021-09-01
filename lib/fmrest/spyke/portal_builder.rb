# frozen_string_literal: true

module FmRest
  module Spyke
    class PortalBuilder < ::Spyke::Associations::Builder
      attr_reader :options

      def klass
        begin
          super
        rescue NameError => e
          ::FmRest::Layout
        end
      end
    end
  end
end
