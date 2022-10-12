# frozen_string_literal: true

module FmRest
  module TokenStore
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def load(key)
        raise NoMethodError
      end

      def store(key, value)
        raise NoMethodError
      end

      def delete(key)
        raise NoMethodError
      end
    end
  end
end
