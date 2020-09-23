# frozen_string_literal: true

module FmRest
  module TokenStore
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def load(key)
        raise NotImplementedError
      end

      def store(key, value)
        raise NotImplementedError
      end

      def delete(key)
        raise NotImplementedError
      end
    end
  end
end
