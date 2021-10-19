# frozen_string_literal: true

require "spec_helper"

require "fmrest/cloud"

RSpec.describe FmRest::Cloud::ClarisIdTokenManager do
  let(:token_store) { FmRest::TokenStore::ShortMemory.new }

  subject do
    described_class.new(
      FMREST_DUMMY_CONFIG.merge({
        token_store: token_store,
        proxy: "http://user:pass@proxy.host"
      })
    )
  end

  before { allow(Aws::CognitoIdentityProvider::Client).to receive(:new) }

  describe "#fetch_token" do
    context "with no token present" do
      before do
        dummy_tokens = double("Tokens",
                              id_token: "DUMMY_ID_TOKEN",
                              refresh_token: "DUMMY_REFRESH_TOKEN")

        dummy_cognito = double("Cognito", authenticate: dummy_tokens)

        allow(Aws::CognitoSrp).to receive(:new).and_return(dummy_cognito)
      end

      it "requests a token through Cognito auth" do
        expect(subject.fetch_token).to eq("DUMMY_ID_TOKEN")
      end

      it "forwards proxy options to the AWS client" do
        expect(Aws::CognitoIdentityProvider::Client).to receive(:new)
          .with(hash_including(http_proxy: "http://user:pass@proxy.host"))

        subject.fetch_token
      end
    end

    context "with no ID token but a refresh token present" do
      before do
        token_store.store(
          "claris-cognito:refresh:#{FMREST_DUMMY_CONFIG[:username]}",
          "DUMMY_REFRESH_TOKEN"
        )

        dummy_tokens = double("Tokens",
                              id_token: "DUMMY_ID_TOKEN",
                              refresh_token: "DUMMY_REFRESH_TOKEN")

        dummy_cognito = double("Cognito", refresh_tokens: dummy_tokens)

        allow(Aws::CognitoSrp).to receive(:new).and_return(dummy_cognito)
      end

      it "requests a token through Cognito refresh" do
        expect(subject.fetch_token).to eq("DUMMY_ID_TOKEN")
      end
    end

    context "with an existing token present" do
      let(:token_store) do
        double("TokenStore", load: "DUMMY_TOKEN", store: nil, delete: nil)
      end

      it "returns the existing token" do
        expect(subject.fetch_token).to eq("DUMMY_TOKEN")
      end
    end
  end

  describe "#expire_token" do
    it "removes the ID token from the token store" do
      token_store.store(
        "claris-cognito:id:#{FMREST_DUMMY_CONFIG[:username]}",
        "DUMMY_ID_TOKEN"
      )

      token_store.store(
        "claris-cognito:refresh:#{FMREST_DUMMY_CONFIG[:username]}",
        "DUMMY_REFRESH_TOKEN"
      )

      expect { subject.expire_token }.to change {
        token_store.load(
          "claris-cognito:id:#{FMREST_DUMMY_CONFIG[:username]}"
        )
      }.from("DUMMY_ID_TOKEN").to(nil)

      expect(token_store.load(
        "claris-cognito:refresh:#{FMREST_DUMMY_CONFIG[:username]}"
      )).to eq("DUMMY_REFRESH_TOKEN")
    end
  end
end
