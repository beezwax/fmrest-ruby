# frozen_string_literal: true

module FmRest
  module TokenStore
    autoload :Base,         "fmrest/token_store/base"
    autoload :Memory,       "fmrest/token_store/memory"
    autoload :Null,         "fmrest/token_store/null"
    autoload :ActiveRecord, "fmrest/token_store/active_record"
    autoload :Moneta,       "fmrest/token_store/moneta"
    autoload :Redis,        "fmrest/token_store/redis"
  end
end
