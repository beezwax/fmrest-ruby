# frozen_string_literal: true

require "spec_helper"
require "fmrest/cloud"

RSpec.describe FmRest::Cloud::AuthErrorHandler do
  describe "#call" do
    let(:env) { Faraday::Env.from(request_headers: {}) }
    let(:token_manager) { double }

    subject { described_class.new(app, {}) }

    before do
      allow(FmRest::Cloud::ClarisIdTokenManager).to receive(:new).and_return(token_manager)
    end

    context "when there's no error" do
      let(:app) { double }

      it "calls the next app in the stack" do
        expect(app).to receive(:call).with(env)
        subject.call(env)
      end
    end

    context "when there's an auth error" do
      let(:app) { -> (env) { raise FmRest::APIError::AccountError, "None shall pass" } }

      it "expires the Claris ID token if there's an auth error and retries the request" do
        expect(token_manager).to receive(:expire_token)
        expect { subject.call(env) }.to raise_error(FmRest::APIError::AccountError)
      end
    end
  end
end
