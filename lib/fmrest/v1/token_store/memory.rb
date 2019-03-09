require "fmrest/v1/token_store/base"

module FmRest
  module V1
    module TokenStore
      class Memory < Base
        def initialize(*args)
          super
          @tokens = {}
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
end
