# frozen_string_literal: true

require "fmrest/token_store/base"
require "redis" unless defined?(MockRedis)

module FmRest
  module TokenStore
    class Redis < Base
      DEFAULT_PREFIX = "fmrest-token:".freeze

      STORE_OPTIONS = [:redis, :prefix].freeze

      def initialize(options = {})
        super
        @redis = @options[:redis] || ::Redis.new(options_for_redis)
        @prefix = @options[:prefix] || DEFAULT_PREFIX
      end

      def load(key)
        @redis.get(prefix_key(key))
      end

      def store(key, value)
        @redis.set(prefix_key(key), value)
        value
      end

      def delete(key)
        @redis.del(prefix_key(key))
      end

      private

      def options_for_redis
        @options.dup.tap do |options|
          STORE_OPTIONS.each { |opt| options.delete(opt) }
        end
      end

      def prefix_key(key)
        "#{@prefix}#{key}"
      end
    end
  end
end
