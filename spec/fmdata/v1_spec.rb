RSpec.describe FmData::V1 do
  describe ".build_connection" do
    context "when not given proper :host or :database options" do
      it "raises a KeyError" do
        expect { FmData::V1.base_connection(host: "example.com") }.to raise_error(KeyError)
        expect { FmData::V1.base_connection(database: "Test DB") }.to raise_error(KeyError)
      end
    end

    context "when passed proper :host and :database options" do
      it "returns a Faraday::Connection with the right URL set" do
        connection = FmData::V1.base_connection(host: "example.com", database: "Test DB")
        expect(connection).to be_a(Faraday::Connection)
        expect(connection.url_prefix.to_s).to eq("https://example.com/fmi/data/v1/databases/Test%20DB/")
      end

      it "passes the given block to the Faraday constructor" do
        dbl = double
        expect(dbl).to receive(:foo) { true }
        FmData::V1.base_connection(host: "example.com", database: "Test DB") { dbl.foo }
      end
    end
  end

  describe ".base_connection" do
    let :connection do
      FmData::V1.build_connection(host: "example.com", database: "Test DB")
    end

    it "returns a Faraday::Connection that uses TokenSession" do
      expect(connection.builder[0]).to eq(FmData::V1::TokenSession)
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
        connection = FmData::V1.build_connection(host: "example.com", database: "Test DB") {}
        expect(connection.builder.handlers).to_not include(FaradayMiddleware::ParseJson)
      end
    end
  end

  describe ".session_path" do
    it "returns just `sessions' when called without a token" do
      expect(FmData::V1.session_path).to eq("sessions")
    end

    it "returns sessions/:token when called with a token" do
      expect(FmData::V1.session_path("+TOKEN+")).to eq("sessions/+TOKEN+")
    end
  end

  describe ".record_path" do
    it "returns layouts/:layout/records when called without an id" do
      expect(FmData::V1.record_path("Some Layout")).to eq("layouts/Some%20Layout/records")
    end

    it "returns layouts/:layout/records/:id when called with an id" do
      expect(FmData::V1.record_path("Some Layout", 1337)).to eq("layouts/Some%20Layout/records/1337")
    end
  end

  describe ".find_path" do
    it "returns layouts/:layout/_find" do
      expect(FmData::V1.find_path("Some Layout")).to eq("layouts/Some%20Layout/_find")
    end
  end
end
