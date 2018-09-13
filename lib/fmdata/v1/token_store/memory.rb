require "fmdata/v1/token_store/base"

module FmData
  module V1
    module TokenStore
      class Memory < Base
        def initialize(database)
          super
          @tokens = {}
        end

        def clear
          @tokens.delete(database)
        end

        def fetch
          @tokens[database]
        end

        def store(token)
          @tokens[database] = token
        end
      end
    end
  end
end
