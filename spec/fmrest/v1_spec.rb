require "spec_helper"

RSpec.describe FmRest::V1 do
  describe ".base_connection" do
    context "when not given proper :host or :database options" do
      it "raises a KeyError" do
        expect { FmRest::V1.base_connection(host: "example.com") }.to raise_error(KeyError)
        expect { FmRest::V1.base_connection(database: "Test DB") }.to raise_error(KeyError)
      end
    end

    context "when passed proper :host and :database options" do
      it "returns a Faraday::Connection with the right URL set" do
        connection = FmRest::V1.base_connection(host: "example.com", database: "Test DB")
        expect(connection).to be_a(Faraday::Connection)
        expect(connection.url_prefix.to_s).to eq("https://example.com/fmi/data/v1/databases/Test%20DB/")
      end

      it "passes the given block to the Faraday constructor" do
        dbl = double
        expect(dbl).to receive(:foo) { true }
        FmRest::V1.base_connection(host: "example.com", database: "Test DB") { dbl.foo }
      end
    end
  end

  describe ".build_connection" do
    let :conn_options do
      { host: "example.com", database: "Test DB" }
    end

    let :connection do
      FmRest::V1.build_connection(conn_options)
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
        connection = FmRest::V1.build_connection(conn_options) {}
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

  describe ".session_path" do
    it "returns just `sessions' when called without a token" do
      expect(FmRest::V1.session_path).to eq("sessions")
    end

    it "returns sessions/:token when called with a token" do
      expect(FmRest::V1.session_path("+TOKEN+")).to eq("sessions/+TOKEN+")
    end
  end

  describe ".record_path" do
    it "returns layouts/:layout/records when called without an id" do
      expect(FmRest::V1.record_path("Some Layout")).to eq("layouts/Some%20Layout/records")
    end

    it "returns layouts/:layout/records/:id when called with an id" do
      expect(FmRest::V1.record_path("Some Layout", 1337)).to eq("layouts/Some%20Layout/records/1337")
    end
  end

  describe ".container_field_path" do
    it "returns layouts/:layout/records/:id/containers/:field_name/1 when called without field_repetition" do
      expect(FmRest::V1.container_field_path("Some Layout", 66, "My Container Field")).to eq("layouts/Some%20Layout/records/66/containers/My%20Container%20Field/1")
    end

    it "returns layouts/:layout/records/:id/containers/:field_name/:field_repetition when called with field_repetition" do
      expect(FmRest::V1.container_field_path("Some Layout", 66, "My Container Field", 10)).to eq("layouts/Some%20Layout/records/66/containers/My%20Container%20Field/10")
    end
  end

  describe ".find_path" do
    it "returns layouts/:layout/_find" do
      expect(FmRest::V1.find_path("Some Layout")).to eq("layouts/Some%20Layout/_find")
    end
  end

  describe ".fetch_container_field" do
    context "when given an invalid URL" do
      it "raises an FmRest::ContainerFieldError" do
        expect { FmRest::V1.fetch_container_field("boo boo") }.to raise_error(FmRest::ContainerFieldError, /Invalid container field URL/)
      end
    end

    context "when given a non-http URL" do
      it "raises an FmRest::ContainerFieldError" do
        expect { FmRest::V1.fetch_container_field("file://foo/bar") }.to raise_error(FmRest::ContainerFieldError, /Container URL is not HTTP/)
      end
    end

    context "when the given URL doesn't return a Set-Cookie header" do
      let(:container_url) { "http://foo.bar/qux" }

      before do
        stub_request(:get, container_url).to_return(body: "foo")
      end

      it "raises an FmRest::ContainerFieldError" do
        expect { FmRest::V1.fetch_container_field(container_url) }.to raise_error(FmRest::ContainerFieldError, /session cookie/)
      end
    end

    context "when the given URL returns a Set-Cookie header" do
      let(:container_url) { "http://foo.bar/qux" }

      before do
        stub_request(:get, container_url).to_return(headers: { "Set-Cookie" => "secret cookie" })
        stub_request(:get, container_url).with(headers: { "Cookie" => "secret cookie" }).to_return(body: "hi there")
      end

      it "returns an IO object with the container field contents" do
        expect(FmRest::V1.fetch_container_field(container_url).read).to eq("hi there")
      end
    end
  end
end
