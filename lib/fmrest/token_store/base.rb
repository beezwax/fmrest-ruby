# frozen_string_literal: true

module FmRest
  module TokenStore
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def load(key)
        raise "Not implemented"
      end

      def store(key, value)
        raise "Not implemented"
      end

      def delete(key)
        raise "Not implemented"
      end
    end
  end
end
