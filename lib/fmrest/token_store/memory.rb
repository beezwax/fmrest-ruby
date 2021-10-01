# frozen_string_literal: true

require "fmrest/token_store/base"

module FmRest
  module TokenStore
    class Memory < Base
      def initialize(*args)
        super
        @@tokens ||= {}
      end

      def delete(key)
        @@tokens.delete(key)
      end

      def load(key)
        @@tokens[key]
      end

      def store(key, value)
        @@tokens[key] = value
      end
    end
  end
end
