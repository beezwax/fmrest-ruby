require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::Serialization do
  let :test_class do
    fmrest_spyke_class do
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
      subject { test_class.new(foo: DateTime.civil(1920, 8, 1, 13, 31, 9)) }

      it "encodes the datetime to a string" do
        expect(subject.to_params).to eq(fieldData: { "Foo" => "08/01/1920 13:31:09" })
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
