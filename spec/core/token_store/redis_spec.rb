# frozen_string_literal: true

require "spec_helper"
require "mock_redis"
require "fmrest/token_store/redis"

require_relative "token_store_examples"

RSpec.describe FmRest::TokenStore::Redis do
  let(:store) { described_class.new }

  before(:all) { Redis = MockRedis }

  it_behaves_like "a token store"

  describe "#initialize" do
    it "sets the Redis object if one is given through :redis option" do
      redis = MockRedis.new
      expect(redis).to receive(:get)
      described_class.new(redis: redis).load("foo")
    end

    it "builds a new Redis connection if none given through :redis option, passing remaining options" do
      expect(Redis).to receive(:new).with({ host: "foo", port: 4500 })
      described_class.new(prefix: "foo", host: "foo", port: 4500)
    end

    it "sets the prefix if one given through :prefix option" do
      redis = MockRedis.new
      expect(redis).to receive(:get).with("whatever:foo")
      described_class.new(redis: redis, prefix: "whatever:").load("foo")
    end

    it "uses the default prefix if none given through :prefix option" do
      redis = MockRedis.new
      expect(redis).to receive(:get).with("fmrest-token:foo")
      described_class.new(redis: redis, prefix: "fmrest-token:").load("foo")
    end
  end

  describe "key prefix" do
    let(:redis) { MockRedis.new }
    let(:store) { described_class.new(redis: redis, prefix: "prefix:") }

    it "is used in #load" do
      expect(redis).to receive(:get).with("prefix:foo")
      store.load("foo")
    end

    it "is used in #store" do
      expect(redis).to receive(:set).with("prefix:foo", anything)
      store.store("foo", "bar")
    end

    it "is used in #delete" do
      expect(redis).to receive(:del).with("prefix:foo")
      store.delete("foo")
    end
  end
end
