require "spec_helper"

require "fixtures/base"

RSpec.describe FmRest::Spyke::Model::Connection do
  describe ".connection" do
    subject { FixtureBase.connection }

    it "returns a Faraday connection" do
      is_expected.to be_a(Faraday::Connection)
    end

    it "builds the correct URL prefix" do
      expect(subject.url_prefix.to_s).to eq("https://example.com/fmi/data/v1/databases/TestDB/")
    end

    it "uses the TokenSession middleware" do
      expect(subject.builder.handlers).to include(FmRest::V1::TokenSession)
    end

    it "uses the EncodeJson middleware" do
      expect(subject.builder.handlers).to include(FaradayMiddleware::EncodeJson)
    end

    it "uses the FmRest::Spyke::SpykeFormatter middleware" do
      expect(subject.builder.handlers).to include(FmRest::Spyke::SpykeFormatter)
    end

    it "uses the TypeCoercer middleware" do
      expect(subject.builder.handlers).to include(FmRest::V1::TypeCoercer)
    end

    it "uses the ParseJson middleware" do
      expect(subject.builder.handlers).to include(FaradayMiddleware::ParseJson)
    end

  end

  describe ".faraday" do
    it "sets a block to be injected into the Faraday connection" do
      rspec = self

      klass = fmrest_spyke_class do
        faraday do |conn|
          rspec.expect(conn).to rspec.be_a(Faraday::Connection)
        end
      end

      klass.connection
    end
  end
end
