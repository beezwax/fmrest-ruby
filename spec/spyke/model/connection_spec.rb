require "spec_helper"

require "fixtures/base"

RSpec.describe FmData::Spyke::Model::Connection do
  describe ".connection" do
    subject { FixtureBase.connection }

    it "returns a Faraday connection" do
      is_expected.to be_a(Faraday::Connection)
    end

    it "builds the correct URL prefix" do
      expect(subject.url_prefix.to_s).to eq("https://example.com/fmi/data/v1/databases/TestDB/")
    end

    it "uses the TokenSession middleware" do
      expect(subject.builder.handlers).to include(FmData::V1::TokenSession)
    end

    it "uses the EncodeJson middleware" do
      expect(subject.builder.handlers).to include(FaradayMiddleware::EncodeJson)
    end

    it "uses the FmData::Spyke::JsonParser middleware" do
      expect(subject.builder.handlers).to include(FmData::Spyke::JsonParser)
    end
  end

  describe ".faraday" do
    it "sets a block to be injected into the Faraday connection" do
      rspec = self

      klass = fmdata_spyke_class do
        faraday do |conn|
          rspec.expect(conn).to rspec.be_a(Faraday::Connection)
        end
      end

      klass.connection
    end
  end
end
