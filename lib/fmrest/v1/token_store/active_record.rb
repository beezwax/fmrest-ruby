warn "FmRest::V1::TokenStore::ActiveRecord is deprecated, use FmRest::TokenStore::ActiveRecord instead"

require "fmrest/token_store/active_record"

module FmRest
  module V1
    module TokenStore
      ActiveRecord = ::FmRest::TokenStore::ActiveRecord
    end
  end
end
