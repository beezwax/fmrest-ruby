# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::V1::Auth do
  let(:extendee) { Object.new.tap { |obj| obj.extend(described_class) } }

  let(:connection) { connection = FmRest::V1.auth_connection(FMREST_DUMMY_CONFIG) }

  describe "#request_auth_token!" do
    it "returns the token when successful" do
      stub_request(:post, fm_url + "/sessions").to_return_fm(token: "imatoken")
      expect(extendee.request_auth_token!(connection)).to eq("imatoken")
    end

    it "raises an exception when auth failed" do
      stub_request(:post, fm_url + "/sessions").to_return_fm(214)
      expect { extendee.request_auth_token!(connection) }.to raise_error(FmRest::APIError::AccountError)
    end
  end

  describe "#request_auth_token" do
    it "returns the token when successful" do
      stub_request(:post, fm_url + "/sessions").to_return_fm(token: "imatoken")
      expect(extendee.request_auth_token(connection)).to eq("imatoken")
    end

    it "returns false when auth failed" do
      stub_request(:post, fm_url + "/sessions").to_return_fm(214)
      expect(extendee.request_auth_token(connection)).to eq(false)
    end
  end
end
