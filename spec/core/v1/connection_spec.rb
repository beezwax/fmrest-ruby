# frozen_string_literal: true

require "spec_helper"

require "fmrest/cloud"

RSpec.describe FmRest::V1::Connection do
  let(:extendee) { Object.new.tap { |obj| obj.extend(described_class) } }

  let(:conn_settings) do
    {
      host: "example.com",
      database: "Test DB",
      username: "bob",
      password: "secret"
    }
  end

  describe "#base_connection" do
    context "when passed proper :host and :database options" do
      it "returns a Faraday::Connection with the right URL set" do
        connection = extendee.base_connection(conn_settings)
        expect(connection).to be_a(Faraday::Connection)
        expect(connection.url_prefix.to_s).to eq("https://example.com/fmi/data/v1/databases/Test%20DB/")
      end

      it "passes the given block to the Faraday constructor" do
        dbl = double
        expect(dbl).to receive(:foo) { true }
        extendee.base_connection(conn_settings) { dbl.foo }
      end

      context "when passed :ssl and :proxy options" do
        it "returns a Faraday::Connection with ssl and proxy options set" do
          connection = extendee.base_connection(conn_settings.merge(ssl: { verify: false }, proxy: "https://foo.bar"))
          expect(connection.ssl.verify).to eq(false)
          expect(connection.proxy.uri.to_s).to eq("https://foo.bar")
        end
      end
    end
  end

  describe "#build_connection" do
    let :connection do
      extendee.build_connection(conn_settings)
    end

    it { expect(connection.builder.handlers).to include(FmRest::V1::RaiseErrors) }
    it { expect(connection.builder.handlers).to include(FmRest::V1::TokenSession) }
    it { expect(connection.builder.handlers).to include(Faraday::Multipart::Middleware) }
    it { expect(connection.builder.handlers).to include(Faraday::Request::Json) }

    context "with no block given" do
      it { expect(connection.builder.handlers).to include(Faraday::Response::Json) }
    end

    context "with a block given" do
      it do
        connection = extendee.build_connection(conn_settings) {}
        expect(connection.builder.handlers).to_not include(Faraday::Response::Json)
      end
    end

    context "with log: true" do
      let :conn_settings do
        {
          host: "example.com",
          database: "Test DB",
          username: "bob",
          password: "secret",
          log:      true
        }
      end

      it { expect(connection.builder.handlers).to include(Faraday::Response::Logger) }
    end

    context "without log: true" do
      it { expect(connection.builder.handlers).to_not include(Faraday::Response::Logger) }
    end
  end

  describe "#auth_connection" do
    let(:connection) { extendee.auth_connection(conn_settings) }

    it { expect(connection.headers).to include("Content-Type" => "application/json") }

    context "when given username and password" do
      context "when the host is FileMaker Cloud" do
        let(:conn_settings) do
          {
            host: "guinea-pig-directory.filemaker-cloud.com",
            database: "Moru DB",
            username: "bob",
            password: "secret"
          }
        end

        it "returns a Faraday::Connection that sets FMID auth headers using the ClarisIdTokenManager" do
          request_stub = stub_request(:post, "https://#{conn_settings[:host]}/")
            .with(headers: { "Authorization" => "FMID ThisIsAToken" })
            .to_return_fm

          dummy_token_manager = double

          allow(dummy_token_manager).to receive(:fetch_token).and_return("ThisIsAToken")
          allow(FmRest::Cloud::ClarisIdTokenManager).to receive(:new).and_return(dummy_token_manager)

          connection.post("/")

          expect(request_stub).to have_been_requested
        end
      end

      context "when the host is a regular FileMaker Server" do
        it "returns a Faraday::Connection that sets HTTP basic auth headers" do
          request_stub = stub_request(:post, "https://#{conn_settings[:host]}/")
            .with(basic_auth: [conn_settings[:username], conn_settings[:password]])
            .to_return_fm

          connection.post("/")

          expect(request_stub).to have_been_requested
        end
      end
    end

    context "when given a fmid_token" do
      let :conn_settings do
        {
          host: "example.com",
          database: "Test DB",
          fmid_token: "ThisIsAToken"
        }
      end

      it "returns a Faraday::Connection that sets FMID auth headers" do
        request_stub = stub_request(:post, "https://#{conn_settings[:host]}/")
          .with(headers: { "Authorization" => "FMID ThisIsAToken" })
          .to_return_fm

        connection.post("/")

        expect(request_stub).to have_been_requested
      end
    end

    it { expect(connection.builder.handlers).to include(FmRest::V1::RaiseErrors) }
    it { expect(connection.builder.handlers).to include(Faraday::Response::Json) }

    context "with log: true" do
      let :conn_settings do
        {
          host: "example.com",
          database: "Test DB",
          username: "bob",
          password: "secret",
          log:      true
        }
      end

      it { expect(connection.builder.handlers).to include(Faraday::Response::Logger) }
    end

    context "without log: true" do
      it { expect(connection.builder.handlers).to_not include(Faraday::Response::Logger) }
    end
  end
end
