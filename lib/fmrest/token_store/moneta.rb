# frozen_string_literal: true

require "fmrest/token_store/base"
require "moneta"

module FmRest
  module TokenStore
    class Moneta < Base
      DEFAULT_ADAPTER = :Memory
      DEFAULT_PREFIX = "fmrest-token:".freeze

      attr_reader :moneta

      # @param options [Hash]
      #   Options to pass to `Moneta.new`
      # @option options [Symbol] :adapter (:Memory)
      #   The Moneta adapter to use
      # @option options [String] :prefix (DEFAULT_PREFIX)
      #   The prefix to use for keys
      def initialize(options = {})
        options = options.dup
        super(options)
        adapter = options.delete(:adapter) || DEFAULT_ADAPTER
        options[:prefix] ||= DEFAULT_PREFIX
        @moneta = ::Moneta.new(adapter, options)
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
