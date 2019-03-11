require "fmrest/v1/token_store/base"
require "redis"
module FmRest
  module V1
    module TokenStore
      class RedisStore < Base

        attr_reader :connection

        def initialize(host, database, options = {})
          super

          @connection = Redis.new
        end

        def store(token)
          connection.set("#{scope}_token", token)
          connection.get("#{scope}_token")
        end

        def fetch
          connection.get("#{scope}_token")
        end

        def clear
          connection.del("#{scope}_token")
        end

      end
    end
  end
end