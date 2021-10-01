# frozen_string_literal: true

require "fmrest/token_store/base"

module FmRest
  module TokenStore
    # Similar to Memory token store, but using instance vars instead of class
    # vars. Mainly useful for specs, where we want to scope token persistance
    # to a spec's context only
    class ShortMemory < Base
      def initialize(*args)
        super
        @tokens ||= {}
      end

      def delete(key)
        @tokens.delete(key)
      end

      def load(key)
        @tokens[key]
      end

      def store(key, value)
        @tokens[key] = value
      end
    end
  end
end
