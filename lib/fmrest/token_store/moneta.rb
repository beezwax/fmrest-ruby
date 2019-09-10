# frozen_string_literal: true

require "fmrest/token_store/base"
require "moneta"

module FmRest
  module TokenStore
    class Moneta < Base
      DEFAULT_BACKEND = :Memory
      DEFAULT_PREFIX = "fmrest-token:".freeze

      attr_reader :moneta

      # @param options [Hash]
      #   Options to pass to `Moneta.new`
      # @option options [Symbol] :backend (:Memory)
      #   The Moneta backend to use
      # @option options [String] :prefix (DEFAULT_PREFIX)
      #   The prefix to use for keys
      def initialize(options = {})
        options = options.dup
        super(options)
        backend = options.delete(:backend) || DEFAULT_BACKEND
        options[:prefix] ||= DEFAULT_PREFIX
        @moneta = ::Moneta.new(backend, options)
      end

      def load(key)
        moneta[key]
      end

      def delete(key)
        moneta.delete(key)
      end

      def store(key, value)
        moneta[key] = value
      end
    end
  end
end
