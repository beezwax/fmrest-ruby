# frozen_string_literal: true

module FmRest
  module TokenStore
    autoload :Base,         "fmrest/token_store/base"
    autoload :Memory,       "fmrest/token_store/memory"
    autoload :Null,         "fmrest/token_store/null"
    autoload :ActiveRecord, "fmrest/token_store/active_record"
    autoload :Moneta,       "fmrest/token_store/moneta"
    autoload :Redis,        "fmrest/token_store/redis"
    autoload :ShortMemory,  "fmrest/token_store/short_memory"

    TOKEN_STORE_INTERFACE = [:load, :store, :delete].freeze

    private

    def token_store
      @token_store ||=
        if TOKEN_STORE_INTERFACE.all? { |method| token_store_option.respond_to?(method) }
          token_store_option
        elsif token_store_option.kind_of?(Class)
          if token_store_option.respond_to?(:instance)
            token_store_option.instance
          else
            token_store_option.new
          end
        else
          FmRest::TokenStore::Memory.new
        end
    end

    def token_store_option
      raise NotImplementedError
    end
  end
end
