require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmData::Spyke::Model::Attributes do
  let :test_class do
    Class.new(Spyke::Base) do
      include FmData::Spyke

      # Needed by ActiveModel::Name
      def self.name; "TestClass"; end

      attributes foo: "Foo", bar: "Bar"
    end
  end

  describe ".attribute_method_matchers" do
    it "doesn't include a plain entry" do
      expect(test_class.attribute_method_matchers.first.method_missing_target).to_not eq("attribute")
    end
  end

  describe ".attributes" do
    it "allows setting mapped attributes" do
      expect(test_class.new(foo: "Boo").attributes).to eq("Foo" => "Boo")
    end
  end

  describe ".mapped_attributes" do
    it "returns a hash of the class' mapped attributes" do
      expect(test_class.mapped_attributes).to eq("foo" => "Foo", "bar" => "Bar")
    end
  end

  describe "#mod_id" do
    it "returns the current mod_id" do
      expect(test_class.new.mod_id).to eq(nil)
    end
  end

  describe "#mod_id=" do
    it "sets the current mod_id" do
      instance = test_class.new
      instance.mod_id = 1
      expect(instance.mod_id).to eq(1)
    end
  end

  describe "attribute setters" do
    it "marks attribute as changed" do
      instance = test_class.new
      expect(instance.foo_changed?).to eq(false)

      instance.foo = "Boo"
      expect(instance.foo_changed?).to eq(true)
    end
  end

  describe "#save" do
    before do
      stub_session_login
      stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_fm({})
    end

    it "resets changes information for self and portal records" do
      ship = Ship.new name: "Mary Celeste"
      expect { ship.save }.to change { ship.changed? }.from(true).to(false)
    end
  end

  describe "#reload" do
    before do
      stub_session_login
      stub_request(:get, fm_url(layout: "Ships", id: 1)).to_return_fm(
        data: [
          {
            fieldData: { name: "Obra Djinn" },
            recordId: 1,
            modId: 0
          }
        ]
      )
    end

    it "resets changes information" do
      ship = Ship.new id: 1, name: "Obra Djinn"
      expect { ship.reload }.to change { ship.changed? }.from(true).to(false)
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

  describe "#attributes=" do
    it "sanitizes parameters" do
      instance = test_class.new
      params = double("ProtectedParams", permitted?: false, empty?: false)
      expect { instance.attributes = params }.to raise_error(ActiveModel::ForbiddenAttributesError)
    end
  end
end
