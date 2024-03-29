# frozen_string_literal: true

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

  describe "class attributes" do
    describe "ignore_mod_id" do
      it { expect(test_class).to respond_to(:ignore_mod_id) }
      it { expect(test_class).to respond_to(:ignore_mod_id=) }
      it { expect(test_class).to respond_to(:ignore_mod_id?) }
      it { expect(test_class.new).to respond_to(:ignore_mod_id) }
      it { expect(test_class.new).to respond_to(:ignore_mod_id=) }
      it { expect(test_class.new).to respond_to(:ignore_mod_id?) }
    end
  end

  describe "#to_params" do
    subject { instance.to_params }

    context "with a new record with no changed fields" do
      let(:instance) { test_class.new }

      it { is_expected.to eq(fieldData: {}) }
    end

    context "with a new record with some changed fields" do
      let(:instance) { test_class.new(foo: "👍") }

      it "includes only the changed fields in fieldData" do
        is_expected.to eq(fieldData: { "Foo" => "👍" })
      end
    end

    context "with a new record with a date field" do
      let(:instance) { test_class.new(foo: Date.civil(1920, 8, 1)) }

      it "encodes the date to a string" do
        is_expected.to eq(fieldData: { "Foo" => "08/01/1920" })
      end
    end

    context "with a new record with a datetime field" do
      let(:instance) { test_class.new(foo: DateTime.civil(2020, 8, 1, 13, 31, 9, '-1')) }

      context "when :timezone is set to nil" do
        it "encodes the datetime to a string, ignoring timezones" do
          is_expected.to eq(fieldData: { "Foo" => "08/01/2020 13:31:09" })
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
              is_expected.to eq(fieldData: { "Foo" => "08/01/2020 07:31:09" })
            end
          end
        end
      end

      [:utc, "utc"].each do |tz|
        context "when :timezone is set to #{tz.inspect}" do
          let(:timezone) { tz }

          it "encodes the datetime to a string, converted to UTC" do
            is_expected.to eq(fieldData: { "Foo" => "08/01/2020 14:31:09" })
          end
        end
      end
    end

    context "with a new record with a time field" do
      let(:instance) { test_class.new(foo: Time.new(1920, 8, 1, 13, 31, 9)) }

      it "encodes the time to a string" do
        is_expected.to eq(fieldData: { "Foo" => "08/01/1920 13:31:09" })
      end
    end

    context "with a new record with a nil field" do
      it "serializes the field as an empty string" do
        record = test_class.new(foo: 1)
        record.foo = nil # trigger dirty
        expect(record.to_params).to eq(fieldData: { "Foo" => "" })
      end
    end

    context "with a new record with a true field" do
      let(:instance) { test_class.new(foo: true) }

      it { is_expected.to eq(fieldData: { "Foo" => 1 }) }
    end

    context "with a new record with a false field" do
      let(:instance) { test_class.new(foo: false) }

      it { is_expected.to eq(fieldData: { "Foo" => 0 }) }
    end

    context "with an existing record with a set modId" do
      let(:instance) { test_class.new(__record_id: "1", __mod_id: "1") }

      it { is_expected.to include(modId: "1") }
    end

    context "with an existing record with a set modId and ignore_mod_id set" do
      let(:instance) do
        test_class.new(__record_id: "1", __mod_id: "1")
          .tap { |instance| instance.ignore_mod_id = true }
      end

      it { is_expected.not_to have_key(:modId) }
    end

    context "with an existing record without a set modId" do
      let(:instance) { test_class.new(__record_id: "1", __mod_id: nil) }

      it { is_expected.not_to have_key(:modId) }
    end

    context "with a record with unpersisted portal data" do
      let(:instance) do
        ship = Ship.new
        ship.crew.build name: "Mortimer"
        ship.crew.build name: "Jojo", parrot_name: "Polly"
        ship.crew.build
        ship
      end

      it "includes the portal data for all portal records with changed attributes" do
        is_expected.to eq(
          fieldData: {},
          portalData: {
            "PiratesPortal" => [
              { "Pirate::Name" => "Mortimer" },
              { "Pirate::Name" => "Jojo", "Parrot::Name" => "Polly" },
              {}
            ]
          }
        )
      end
    end

    context "with a record with persisted portal data" do
      let(:instance) do
        ship = Ship.new
        ship.crew.build name: "Mortimer", __record_id: 1
        ship.crew.build name: "Jojo", __record_id: 2
        ship
      end

      it "includes a single portal deletion" do
        instance.crew.first.mark_for_destruction

        is_expected.to include(
          fieldData: {
            deleteRelated: "PiratesPortal.1"
          }
        )
      end

      it "includes multiple portal deletions" do
        instance.crew.each(&:mark_for_destruction)

        is_expected.to match(
          fieldData: {
            deleteRelated: ["PiratesPortal.1", "PiratesPortal.2"]
          }
        )
      end
    end
  end
end
