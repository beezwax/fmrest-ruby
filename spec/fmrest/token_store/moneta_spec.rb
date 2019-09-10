require "spec_helper"
require "moneta"
require "fmrest/token_store/moneta"

require_relative "token_store_examples"

RSpec.describe FmRest::TokenStore::Moneta do
  let(:store) { described_class.new }

  it_behaves_like "a token store"

  describe "#initialize" do
    xit "sets the given backend for Moneta" do
    end

    xit "sets the given :prefix for Moneta" do
    end
  end
end
