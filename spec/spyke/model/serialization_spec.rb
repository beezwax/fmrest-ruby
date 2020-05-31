require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::Serialization do
  let(:timezone) { nil }

  let(:conn_settings) {
    { timezone: timezone }
  }

  let :test_class do
    config = conn_settings
    fmrest_spyke_class do
      self.fmrest_config = config
      attributes foo: "Foo", bar: "Bar"
    end
  end

  describe "#to_params" do
    context "with a new record with no changed fields" do
      subject { test_class.new }

      it "returns an empty fieldData" do
        expect(subject.to_params).to eq(fieldData: {})
      end
    end

    context "with a new record with some changed fields" do
      subject { test_class.new(foo: "👍") }

      it "includes only the changed fields in fieldData" do
        expect(subject.to_params).to eq(fieldData: { "Foo" => "👍" })
      end
    end

    context "with a new record with a date field" do
      subject { test_class.new(foo: Date.civil(1920, 8, 1)) }

      it "encodes the date to a string" do
        expect(subject.to_params).to eq(fieldData: { "Foo" => "08/01/1920" })
      end
    end

    context "with a new record with a datetime field" do
      subject { test_class.new(foo: DateTime.civil(2020, 8, 1, 13, 31, 9, '-1')) }

      context "when :timezone is set to nil" do
        it "encodes the datetime to a string, ignoring timezones" do
          expect(subject.to_params).to eq(fieldData: { "Foo" => "08/01/2020 13:31:09" })
        end
      end

      [:local, "local"].each do |tz|
        context "when :timezone is set to #{tz.inspect}" do
          let(:timezone) { tz }

          it "encodes the datetime to a string, converted to local timezone" do
            # Take advantage of ActiveSupport's TimeZone for testing
            # independently of the system timezone
            Time.use_zone("Pacific Time (US & Canada)") do
              # On this date it's PDT, so UTC offset is -7hs
              expect(subject.to_params).to eq(fieldData: { "Foo" => "08/01/2020 07:31:09" })
            end
          end
        end
      end

      [:utc, "utc"].each do |tz|
        context "when :timezone is set to #{tz.inspect}" do
          let(:timezone) { tz }

          it "encodes the datetime to a string, converted to UTC" do
            expect(subject.to_params).to eq(fieldData: { "Foo" => "08/01/2020 14:31:09" })
          end
        end
      end
    end

    context "with a new record with a time field" do
      subject { test_class.new(foo: Time.new(1920, 8, 1, 13, 31, 9)) }

      it "encodes the time to a string" do
        expect(subject.to_params).to eq(fieldData: { "Foo" => "08/01/1920 13:31:09" })
      end
    end

    context "with a record with portal data" do
      subject do
        ship = Ship.new
        ship.crew.build name: "Mortimer"
        ship.crew.build name: "Jojo"
        ship.crew.build
        ship
      end

      it "includes the portal data for all portal records with changed attributes" do
        expect(subject.to_params).to eq(
          fieldData: {},
          portalData: {
            "PiratesTable" => [
              { "Pirate::name" => "Mortimer" },
              { "Pirate::name" => "Jojo" }
            ]
          }
        )
      end
    end
  end
end
