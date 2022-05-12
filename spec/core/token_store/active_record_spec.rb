# frozen_string_literal: true

require "spec_helper"
require "fmrest/token_store/active_record"
require "sqlite3"

require_relative "token_store_examples"

RSpec.describe FmRest::TokenStore::ActiveRecord do
  let(:store) { FmRest::TokenStore::ActiveRecord.new }

  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: File.join(__dir__, "../../db/test.sqlite3")
    )

    # Uncomment this to get queries logged to STDOUT
    # ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
  end

  # Close SQL connection after running specs
  after(:all) do
    ActiveRecord::Base.remove_connection
  end

  # Run specs as SQL transactions and roll them back after
  around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  it_behaves_like "a token store"

  describe "#initialize" do
    it "creates the tokens table" do
      expect { store }.to change {
        ActiveRecord::Base.connection.table_exists?(FmRest::TokenStore::ActiveRecord::DEFAULT_TABLE_NAME)
      }.from(false).to(true)
    end

    it "creates the tokens table with the given name in :table_name option" do
      expect { FmRest::TokenStore::ActiveRecord.new(table_name: "i_like_tokens") }.to change {
        ActiveRecord::Base.connection.table_exists?(:i_like_tokens)
      }.from(false).to(true)
    end
  end
end
