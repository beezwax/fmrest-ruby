require "fmrest/v1/token_store/base"

module FmRest
  module V1
    module TokenStore
      class Memory < Base
        def initialize(host, database, options = {})
          super
          @tokens = {}
        end

        def clear
          @tokens.delete(scope)
        end

        def fetch
          @tokens[scope]
        end

        def store(token)
          @tokens[scope] = token
        end
      end
    end
  end
end
