# frozen_string_literal: true

module FmRest
  module TokenStore
    class Null < Base
      def delete(key); end
      def load(key); end
      def store(key, value); end
    end
  end
end
