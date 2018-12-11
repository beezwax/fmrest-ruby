require "spec_helper"

RSpec.describe FmData::V1::TokenSession do
  describe "#initialize" do
    xit "sets options"
  end

  describe "#call" do
    context "with a valid token" do
      xit "sets the auth header"
    end

    context "without a valid token" do
      xit "request a new token"
      xit "retries"
    end
  end
end
