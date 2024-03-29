# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::ConnectionSettings do
  let(:basic) do
    {
      host: "host.somewhere",
      username: "bob",
      password: "secret",
      database: "xyz",
      fmid_token: -> { "token".upcase }
    }
  end

  subject { described_class.new(basic) }

  describe ".wrap" do
    it "returns the given argument if it's already a ConnectionSettings instance" do
      expect(described_class.wrap(subject)).to equal(subject)
    end

    it "validates the given ConnectionSettings instance" do
      expect(subject).to receive(:validate)
      described_class.wrap(subject)
    end

    it "doesn't validate the given ConnectionSettings instance if skip_validation: true is given" do
      expect(subject).to_not receive(:validate)
      described_class.wrap(subject, skip_validation: true)
    end

    it "returns a new ConnectionSettings instance if given a hash" do
      expect(described_class.wrap(basic)).to be_a(described_class)
    end

    it "passes the skip_validation option to .new" do
      expect(described_class).to receive(:new).with(anything, skip_validation: true)
      described_class.wrap({}, skip_validation: true)
    end
  end

  describe "#initialize" do
    it "normalizes alias properties" do
      settings_hash = basic
      settings_hash[:account_name] = settings_hash.delete(:username)
      expect(described_class.new(settings_hash).username).to eq("bob")
    end

    it "validates missing properties" do
      expect { described_class.new({}) }.to raise_error(FmRest::ConnectionSettings::MissingSetting, /`host', `database'/)
      expect { described_class.new({host: "foo", database: "bar"}) }.to raise_error(FmRest::ConnectionSettings::MissingSetting, /`username', `fmid_token' or `token'/)
    end

    it "doesn't validate if skip_validation: true is given" do
      expect { described_class.new({}, skip_validation: true) }.to_not raise_error
    end

    it "creates a copy if given a ConnectionSettings object" do
      settings = described_class.new(subject)
      expect(settings.username).to eq(subject.username)
    end
  end

  describe "#[]" do
    it "returns the requested property or its default, indifferent of access key (symbol or string)" do
      expect(subject[:username]).to eq("bob")
      expect(subject["username"]).to eq("bob")
      expect(subject[:autologin]).to eq(true)
      expect(subject[:log]).to eq(false)
      expect(subject[:log_level]).to eq(:debug)
      expect(subject[:date_format]).to eq(FmRest::ConnectionSettings::DEFAULT_DATE_FORMAT)
      expect(subject[:time_format]).to eq(FmRest::ConnectionSettings::DEFAULT_TIME_FORMAT)
      expect(subject[:timestamp_format]).to eq(FmRest::ConnectionSettings::DEFAULT_TIMESTAMP_FORMAT)
      expect(subject[:coerce_dates]).to eq(false)
      expect(subject[:cloud]).to eq(:auto)
    end

    it "evaluates procs" do
      expect(subject[:fmid_token]).to eq("TOKEN")
    end

    it "returns the requested property's default only if it was not given explicitly" do
      config = described_class.new({ host: "host", username: "bob", database: "xyz" })
      expect(config[:autologin]).to eq(true)

      config = described_class.new({ host: "host", username: "bob", database: "xyz", autologin: false })
      expect(config[:autologin]).to eq(false)
    end

    it "raises an exception if the requested property is not recognized" do
      expect { subject[:peekaboo] }.to raise_error(ArgumentError, "Unknown setting `peekaboo'")
    end
  end

  describe "#to_h" do
    it "returns a new hash with the non-default properties" do
      settings = described_class.new(basic.merge(
        date_format: FmRest::ConnectionSettings::DEFAULT_DATE_FORMAT,
        ssl: nil
      ))
      expect(settings.to_h).to eq(basic)
    end
  end

  describe "#merge" do
    it "creates a new ConnectionSettings instance with properties merged with the passed settings" do
      merged = subject.merge({ username: "bobby" })
      expect(merged.username).to eq("bobby")
      expect(merged.password).to eq("secret")
    end
  end

  FmRest::ConnectionSettings::PROPERTIES.each do |p|
    describe "##{p}" do
      it { expect(subject.send(p)).to eq(subject[p]) }
    end

    describe "##{p}?" do
      it { expect(subject.send("#{p}?")).to eq(!!subject[p]) }
    end
  end
end
