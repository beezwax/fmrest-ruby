require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::Attributes do
  let :test_class do
    fmrest_spyke_class do
      attributes foo: "Foo", bar: "Bar"
    end
  end

  it "includes ActiveModel::Dirty" do
    expect(test_class.included_modules).to include(::ActiveModel::Dirty)
  end

  it "includes ActiveModel::ForbiddenAttributesProtection" do
    expect(test_class.included_modules).to include(::ActiveModel::ForbiddenAttributesProtection)
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

    it "creates dirty methods for the given attributes" do
      instance = test_class.new(foo: "Bar")

      expect(instance).to respond_to(:foo_will_change!)
      expect(instance.foo_changed?).to be(true)
    end

    it "raises an error, if attempting to set an attribute named id" do
      expect do
        fmrest_spyke_class do
          attributes id: "Foo", bar: "Bar"
        end
      end.to raise_error("id is reserved for the record_id")
    end
  end

  describe ".mapped_attributes" do
    it "returns a hash of the class' mapped attributes" do
      expect(test_class.mapped_attributes).to eq("foo" => "Foo", "bar" => "Bar")
    end

    it "defaults to a HashWithIndifferentAccess" do
      expect(fmrest_spyke_class.mapped_attributes).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end
  end

  describe "#id_will_change!" do
    it "is defined" do
      expect(test_class.new).to respond_to(:id_will_change!)
    end
  end

  describe "#id=" do
    it "calls id_will_change!" do
      instance = test_class.new
      expect(instance).to receive(:id_will_change!)
      instance.id = 1
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

  describe "#reload" do
    let(:ship) { Ship.new id: 1, name: "Obra Djinn" }

    before { stub_session_login }

    context "when successful" do
      before do
        stub_request(:get, fm_url(layout: "Ships", id: 1)).to_return_fm(
          data: [
            {
              fieldData: { name: "Obra Djinn" },
              recordId: "1",
              modId: "0"
            }
          ]
        )
      end

      it "resets changes information" do
        ship = Ship.new id: 1, name: "Obra Djinn"
        expect { ship.reload }.to change { ship.changed? }.from(true).to(false)
      end
    end

    context "when unsuccesful" do
      before do
        stub_request(:get, fm_url(layout: "Ships", id: 1)).to_return_fm(false)
      end

      it "raises an error" do
        expect { ship.reload }.to raise_error(FmRest::APIError)
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
