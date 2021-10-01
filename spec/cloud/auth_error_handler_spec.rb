# frozen_string_literal: true

require "spec_helper"

require "fmrest/cloud"

RSpec.describe FmRest::Cloud::AuthErrorHandler do
  describe "#call" do
    it "expires the Claris ID token if there's an auth error and retries the request" do
      responses = [
        [401, {}, "Unauthorized"],
        [200, {}, "OK"]
      ]

      faraday = Faraday.new do |conn|
        conn.use described_class, {}
        conn.use FmRest::V1::RaiseErrors

        conn.adapter :test do |stub|
          stub.get '/' do
            responses.shift
          end
        end
      end

      dummy_token_manager = double

      expect(dummy_token_manager).to receive(:expire_token)

      allow(FmRest::Cloud::ClarisIdTokenManager).to receive(:new).and_return(dummy_token_manager)

      expect(faraday.get("/").body).to eq("OK")
    end
  end
end
