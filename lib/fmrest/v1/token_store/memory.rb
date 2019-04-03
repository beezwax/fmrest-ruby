# frozen_string_literal: true

warn "FmRest::V1::TokenStore::Memory is deprecated, use FmRest::TokenStore::Memory instead"

require "fmrest/token_store/memory"

module FmRest
  module V1
    module TokenStore
      Memory = ::FmRest::TokenStore::Memory
    end
  end
end
