# frozen_string_literal: true

# Use ActiveRecord token store
FmRest.token_store = FmRest::TokenStore::ActiveRecord

# Use ActiveRecord token store with custom table name
# FmRest.token_store = FmRest::TokenStore::ActiveRecord.new(table_name: "my_token_store")

# Use Redis token store (requires redis gem)
# FmRest.token_store = FmRest::TokenStore::Redis

# Use Redis token store with custom prefix
# FmRest.token_store = FmRest::TokenStore::Redis.new(prefix: "my-fmrest-token:")

# Use Moneta token store (requires moneta gem)
# FmRest.token_store = FmRest::TokenStore::Moneta.new(backend: )

# Use Memory token store (not suitable for production)
# FmRest.token_store = FmRest::TokenStore::Memory
