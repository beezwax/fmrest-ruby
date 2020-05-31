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

  describe ".fmrest_config" do
    it "defaults to FmRest.default_connection_settings" do
      old_settings = FmRest.default_connection_settings
      FmRest.default_connection_settings = { host: "hi imma host" }
      expect(FmRest::Spyke::Base.fmrest_config).to eq(FmRest.default_connection_settings)
      FmRest.default_connection_settings = old_settings
    end

    it "gets overwriten in subclasses if self.fmrest_config= is used" do
      subclass = fmrest_spyke_class do
        self.fmrest_config = { host: "foo" }
      end
      expect(subclass.fmrest_config).to eq(host: "foo")
    end
  end

  describe "#fmrest_config" do
    it "returns the value of the class-level .fmrest_config" do
      subclass = fmrest_spyke_class do
        self.fmrest_config = { host: "foo" }
      end
      expect(subclass.new.fmrest_config).to eq(host: "foo")
    end
  end
end
