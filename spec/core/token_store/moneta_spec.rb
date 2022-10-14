# frozen_string_literal: true

require "spec_helper"
require "fmrest/token_store/moneta"

require_relative "token_store_examples"

RSpec.describe FmRest::TokenStore::Moneta do
  subject(:store) { described_class.new }

  it_behaves_like "a token store"

  describe "#initialize" do
    let(:moneta_instance) { double(:Moneta) }

    it "creates a default Moneta instance" do
      allow(::Moneta).to receive(:new).and_return(moneta_instance)
      expect(store.moneta).to eq(moneta_instance)
    end

    it "with no options given, passes default adapter and prefix to Moneta initializer" do
      expect(::Moneta).to receive(:new).with(:Memory, { prefix: "fmrest-token:" })
      described_class.new
    end

    it "with options given passes adapter, prefix and other options to Moneta initializer" do
      expect(::Moneta).to receive(:new).with(:Memcached, { prefix: "prefix:", server: "localhost:1111" })
      described_class.new(adapter: :Memcached, prefix: "prefix:", server: "localhost:1111")
    end
  end
end
