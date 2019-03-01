require "spec_helper"

RSpec.describe FmRest::V1::Connection do
  let(:extendee) { Object.new.tap { |obj| obj.extend(described_class) } }

  describe "#base_connection" do
    context "when not given proper :host or :database options" do
      it "raises a KeyError" do
        expect { extendee.base_connection(host: "example.com") }.to raise_error(KeyError)
        expect { extendee.base_connection(database: "Test DB") }.to raise_error(KeyError)
      end
    end

    context "when passed proper :host and :database options" do
      it "returns a Faraday::Connection with the right URL set" do
        connection = extendee.base_connection(host: "example.com", database: "Test DB")
        expect(connection).to be_a(Faraday::Connection)
        expect(connection.url_prefix.to_s).to eq("https://example.com/fmi/data/v1/databases/Test%20DB/")
      end

      it "passes the given block to the Faraday constructor" do
        dbl = double
        expect(dbl).to receive(:foo) { true }
        extendee.base_connection(host: "example.com", database: "Test DB") { dbl.foo }
      end
    end
  end

  describe "#build_connection" do
    let :conn_options do
      { host: "example.com", database: "Test DB" }
    end

    let :connection do
      extendee.build_connection(conn_options)
    end

    it "returns a Faraday::Connection that uses RaiseErrors" do
      expect(connection.builder.handlers).to include(FmRest::V1::RaiseErrors)
    end

    it "returns a Faraday::Connection that uses TokenSession" do
      expect(connection.builder.handlers).to include(FmRest::V1::TokenSession)
    end

    it "returns a Faraday::Connection that encodes requests as multipart/form-data when appropriate" do
      expect(connection.builder.handlers).to include(Faraday::Request::Multipart)
    end

    it "returns a Faraday::Connection that encodes requests as JSON" do
      expect(connection.builder.handlers).to include(FaradayMiddleware::EncodeJson)
    end

    context "with no block given" do
      it "returns a Faraday::Connection that parses responses as JSON" do
        expect(connection.builder.handlers).to include(FaradayMiddleware::ParseJson)
      end
    end

    context "with a block given" do
      it "doesn't return a Faraday::Connection that parses responses as JSON" do
        connection = extendee.build_connection(conn_options) {}
        expect(connection.builder.handlers).to_not include(FaradayMiddleware::ParseJson)
      end
    end

    context "with log: true" do
      let :conn_options do
        { host: "example.com", database: "Test DB", log: true }
      end

      it "uses the logger Faraday middleware" do
        expect(connection.builder.handlers).to include(Faraday::Response::Logger)
      end
    end

    context "without log: true" do
      it "doesn't use the logger Faraday middleware" do
        expect(connection.builder.handlers).to_not include(Faraday::Response::Logger)
      end
    end
  end
end
