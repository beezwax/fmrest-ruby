require "spec_helper"
require "fmrest/token_store/active_record"

RSpec.describe FmRest::TokenStore::ActiveRecord do
  let(:store) { FmRest::TokenStore::ActiveRecord.new }

  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: File.join(__dir__, "../../db/test.sqlite3")
    )

    #ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
  end

  after(:all) do
    ActiveRecord::Base.remove_connection
  end

  around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

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

  describe "#store" do
    it "stores the given token" do
      store.store("hostname:Database Name", "bar")
      expect(store.load("hostname:Database Name")).to eq("bar")
    end
  end

  describe "#load" do
    it "returns nil when no stored token exists" do
      expect(store.load("miss")).to be_nil
    end

    it "returns the token value when a stored token exists" do
      store.store("hit", "token")
      expect(store.load("hit")).to eq("token")
    end
  end

  describe "#delete" do
    it "deletes the token for the given key" do
      store.store("hostname:DB Name", "token")
      store.delete("hostname:DB Name")
      expect(store.load("hostname:DB Name")).to be_nil
    end
  end
end
