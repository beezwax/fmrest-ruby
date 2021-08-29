require "spec_helper"
require "fmrest/token_store/memory"

RSpec.describe FmRest::V1::TokenSession do
  let(:token_store) { FmRest::TokenStore::Memory.new }
  let(:config_token) { nil }

  let(:hostname) { "stub" }

  let(:autologin) { true }

  let(:config) do
    {
      host:        "https://#{hostname}",
      database:    "MyDB",
      username:    "bobby",
      password:    "cubictrousers",
      token_store: token_store,
      token:       config_token,
      autologin:   autologin
    }
  end

  let :faraday do
    Faraday.new("https://#{hostname}") do |conn|
      conn.use FmRest::V1::TokenSession, FmRest::ConnectionSettings.new(config)
      conn.response :json
      conn.adapter Faraday.default_adapter
    end
  end

  describe "#call" do
    before do
      token_store.store("#{hostname}:#{config[:database]}:#{config[:username]}", token)
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

      context "when :autologin is true" do
        it "request a new token and stores it" do
          faraday.get("/")
          expect(@session_request).to have_been_requested.once
          expect(token_store.load("#{hostname}:#{config[:database]}:#{config[:username]}")).to eq(new_token)
        end

        it "resends the request" do
          faraday.get("/")
          expect(@retry_request).to have_been_requested.once
        end
      end

      context "when autologin is false" do
        let(:autologin) { false }

        it "does not request a new token" do
          stub_request(:get, "https://#{hostname}/").to_return_fm
          faraday.get("/")
          expect(@session_request).to_not have_been_requested
        end
      end

      context "when a token is given in connection settings" do
        let(:config_token) { new_token }

        it "uses that token instead of requesting one" do
          faraday.get("/")
          expect(@retry_request).to have_been_requested.once
          expect(@session_request).to_not have_been_requested
        end
      end
    end

    context "with an fmid_token set in connection settings" do
      let(:config) do
        {
          host:        "https://#{hostname}",
          database:    "MyDB",
          fmid_token:  "very-long-cognito-id-token",
          token_store: token_store,
          token:       config_token,
          autologin:   autologin
        }
      end

      context "with a valid token" do
        let(:token) { "FILEMAKER_CLOUD_TOKEN" }

        before do
          token_store.store("#{hostname}:#{config[:database]}:#{Digest::SHA256.hexdigest(config[:fmid_token])}", token)

          @stubbed_request =
            stub_request(:get, "https://#{hostname}/").with(headers: { "Authorization" => "Bearer #{token}" }).to_return_fm
        end

        it "sets the token header" do
          faraday.get("/")
          expect(@stubbed_request).to have_been_requested.once
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
        expect(token_store.load("#{hostname}:#{config[:database]}:#{config[:username]}")).to eq(new_token)
      end

      it "resends the request" do
        faraday.get("/")
        expect(@init_request).to have_been_requested.once
        expect(@retry_request).to have_been_requested.once
      end

      context "when autologin is false" do
        let(:autologin) { false }

        it "does not request a new token" do
          faraday.get("/")
          expect(@session_request).to_not have_been_requested
        end
      end
    end

    context "when requesting a logout" do
      let(:token) { "THE_ACTUAL_TOKEN" }

      before do
        @logout_request_with_auth_header =
          stub_request(:delete, fm_url(host: hostname, database: config[:database]) + "/sessions/#{token}")
            .with(headers: { Authorization: "Bearer #{token}" })

        @logout_request =
          stub_request(:delete, fm_url(host: hostname, database: config[:database]) + "/sessions/#{token}").to_return_fm
      end

      it "doesn't set the token header" do
        faraday.delete("/fmi/data/v1/databases/#{config[:database]}/sessions/REPLACEABLE")
        expect(@logout_request_with_auth_header).to_not have_been_requested
      end

      it "replaces the dummy token in the path with the actual session token" do
        faraday.delete("/fmi/data/v1/databases/#{config[:database]}/sessions/REPLACEABLE")
        expect(@logout_request).to have_been_requested
      end

      it "deletes the token from the token store" do
        expect(token_store).to receive(:delete)
        faraday.delete("/fmi/data/v1/databases/#{config[:database]}/sessions/REPLACEABLE")
      end

      context "with no token set" do
        let(:token) { nil }

        it "raises an exception" do
          expect { faraday.delete("/fmi/data/v1/databases/#{config[:database]}/sessions/REPLACEABLE") }.to(
            raise_error(FmRest::V1::TokenSession::NoSessionTokenSet)
          )
        end
      end
    end
  end
end
