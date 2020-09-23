# frozen_string_literal: true

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

    it "recycles the same connection when there's no overlay" do
      expect(FixtureBase.connection).to equal(FixtureBase.connection)
    end

    it "returns a new connection each time if there's an overlay" do
      FixtureBase.fmrest_config_overlay = { host: "foo.bar.qux" }
      expect(FixtureBase.connection).to_not equal(FixtureBase.connection)
      FixtureBase.clear_fmrest_config_overlay
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

    it "passes on its value to subclasses" do
      old_settings = FixtureBase.fmrest_config
      FixtureBase.fmrest_config = { host: "dad says" }
      child = Class.new(FixtureBase)
      expect(child.fmrest_config.to_h).to eq(host: "dad says")
      FixtureBase.fmrest_config = old_settings
    end

    it "gets overwriten if self.fmrest_config= is used" do
      subclass = fmrest_spyke_class do
        self.fmrest_config = { host: "foo", database: "bar" }
      end
      expect(subclass.fmrest_config.to_h).to eq(host: "foo", database: "bar")
    end
  end

  describe "#fmrest_config" do
    it "returns the value of the class-level .fmrest_config" do
      subclass = fmrest_spyke_class do
        self.fmrest_config = { host: "foo" }
      end
      expect(subclass.new.fmrest_config.to_h).to eq(host: "foo")
    end
  end

  describe ".fmrest_config_overlay" do
    after(:each) { FixtureBase.clear_fmrest_config_overlay }

    it "overlays the given properties on .fmrest_config" do
      FixtureBase.fmrest_config_overlay = { username: "alice" }
      expect(FixtureBase.fmrest_config.username).to eq("alice")
    end

    it "inherits overlays from parent classes" do
      FixtureBase.fmrest_config_overlay = { username: "alice" }
      child = Class.new(FixtureBase)
      expect(child.fmrest_config.username).to eq("alice")
    end
  end

  describe ".with_overlay" do
    it "overlays the given properties within the passed block" do
      FixtureBase.with_overlay(username: "nikki") do
        expect(FixtureBase.fmrest_config.username).to eq("nikki")
      end

      expect(FixtureBase.fmrest_config.username).not_to eq("nikki")
    end
  end
end
