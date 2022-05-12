# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples "a token store" do
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
