# frozen_string_literal: true

require "spec_helper"
require "fmrest/cloud"

RSpec.describe "Cognito refresh token flow" do
  let(:calls) { [] }
  let(:token_manager) { double }
  let(:faraday) do
    responses = [
      [401, {}, "Unauthorized"],
      [200, {}, "OK"]
    ]

    tokens = %w{ TOKEN_A TOKEN_B }

    Faraday.new do |conn|
      conn.use FmRest::Cloud::AuthErrorHandler, {}
      conn.use FmRest::V1::RaiseErrors
      conn.request :authorization, "FMID", -> { tokens.shift }

      conn.adapter :test do |stub|
        stub.get '/' do |env|
          calls << env.deep_dup
          responses.shift
        end
      end
    end
  end

  before do
    allow(FmRest::Cloud::ClarisIdTokenManager).to receive(:new).and_return(token_manager)
    expect(token_manager).to receive(:expire_token)
    faraday.get("/")
  end

  it "fetches the token on the first request" do
    expect(calls.first.request_headers).to include("Authorization" => "FMID TOKEN_A")
  end

  it "fetches the token again on the second request" do
    expect(calls.last.request_headers).to include("Authorization" => "FMID TOKEN_B")
  end

  it("retries") { expect(calls.last.response.body).to eq("OK") }
end
