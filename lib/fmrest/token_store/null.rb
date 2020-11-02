# frozen_string_literal: true

require "singleton"

module FmRest
  module TokenStore
    module Null < Base
      include Singleton

      def delete(key)
      end

      def load(key)
      end

      def store(key, value)
      end
    end
  end
end
