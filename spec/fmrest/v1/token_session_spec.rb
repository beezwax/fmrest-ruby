require "spec_helper"
require "fmrest/token_store/memory"

RSpec.describe FmRest::V1::TokenSession do
  let(:token_store) { FmRest::TokenStore::Memory.new }

  let(:hostname) { "stub" }

  let(:config) do
    {
      host:        "https://#{hostname}",
      database:    "My DB",
      username:    "bobby",
      password:    "cubictrousers",
      token_store: token_store
    }
  end

  let :faraday do
    Faraday.new("https://#{hostname}") do |conn|
      conn.use FmRest::V1::TokenSession, config
      conn.response :json
      conn.adapter Faraday.default_adapter
    end
  end

  describe "#initialize" do
    xit "sets options"
  end

  describe "#call" do
    before do
      token_store.store("#{hostname}:#{config[:database]}", token)
    end

    context "with a valid token" do
      let(:token) { "TOP_SECRET_TOKEN" }

      before do
        @stubbed_request =
          stub_request(:get, "https://#{hostname}/").with(headers: { "Authorization" => "Bearer #{token}" }).to_return_fm
      end

      it "sets the token header" do
        faraday.get("/")
        expect(@stubbed_request).to have_been_requested.once
      end
    end

    context "without a token" do
      let(:token) { nil }
      let(:new_token) { "SHINY_NEW_TOKEN" }

      before do
        @retry_request = stub_request(:get, "https://#{hostname}/").with(headers: { "Authorization" => "Bearer #{new_token}" }).to_return_fm
        @session_request = stub_request(:post, fm_url(host: hostname, database: config[:database]) + "/sessions").to_return_fm(token: new_token)
      end

      it "request a new token and stores it" do
        faraday.get("/")
        expect(@session_request).to have_been_requested.once
        expect(token_store.load("#{hostname}:#{config[:database]}")).to eq(new_token)
      end

      it "resends the request" do
        faraday.get("/")
        expect(@retry_request).to have_been_requested.once
      end

      context "without :username or :account_name options given" do
        it "raises an exception" do
          config.delete(:username)
          config.delete(:account_name)
          expect { faraday.get("/") }.to raise_error(KeyError, /:username/)
        end
      end

      context "with :account_name option given instead of :username" do
        it "doesn't raise an exception" do
          config[:account_name] = config[:username]
          config.delete(:username)
          expect { faraday.get("/") }.not_to raise_error
        end
      end
    end

    context "with an invalid token" do
      let(:token) { "INVALID_TOKEN" }
      let(:new_token) { "SHINY_NEW_TOKEN" }

      before do
        @init_request = stub_request(:get, "https://#{hostname}/").with(headers: { "Authorization" => "Bearer #{token}" }).to_return(status: 401)
        @retry_request = stub_request(:get, "https://#{hostname}/").with(headers: { "Authorization" => "Bearer #{new_token}" }).to_return_fm
        @session_request = stub_request(:post, fm_url(host: hostname, database: config[:database]) + "/sessions").to_return_fm(token: new_token)
      end

      it "request a new token and stores it" do
        faraday.get("/")
        expect(@session_request).to have_been_requested.once
        expect(token_store.load("#{hostname}:#{config[:database]}")).to eq(new_token)
      end

      it "resends the request" do
        faraday.get("/")
        expect(@init_request).to have_been_requested.once
        expect(@retry_request).to have_been_requested.once
      end
    end
  end
end
