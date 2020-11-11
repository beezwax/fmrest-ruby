# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::Spyke::Model::RecordID do
  let :test_class do
    fmrest_spyke_class do
      attributes foo: "Foo", bar: "Bar"
    end
  end

  describe "primary_key" do
    it "gets set to :__record_id" do
      expect(test_class.primary_key).to eq(:__record_id)
    end
  end

  describe "#__record_id" do
    it "returns the current __record_id" do
      expect(test_class.new.__record_id).to eq(nil)
    end
  end

  describe "#__record_id=" do
    it "sets the current record_id" do
      instance = test_class.new
      instance.__record_id = 1
      expect(instance.record_id).to eq(1)
    end
  end

  describe "#record_id" do
    it "is an alias of #__record_id" do
      expect(test_class.instance_method(:record_id)).to eq(test_class.instance_method(:__record_id))
    end
  end

  describe "#id" do
    it "is an alias of #__record_id" do
      expect(test_class.instance_method(:id)).to eq(test_class.instance_method(:__record_id))
    end
  end

  describe "#__record_id?" do
    it "returns true if __record_id is set" do
      expect(test_class.new(__record_id: 1).__record_id?).to eq(true)
    end

    it "returns false if __record_id is not set" do
      expect(test_class.new.__record_id?).to eq(false)
    end
  end

  describe "#record_id?" do
    it "is an alias of #__record_id?" do
      expect(test_class.instance_method(:record_id?)).to eq(test_class.instance_method(:__record_id?))
    end
  end

  describe "#hash" do
    it "returns the hash of #__record_id" do
      id = double(hash: "hashed!")
      expect(test_class.new(__record_id: id).hash).to eq("hashed!")
    end
  end

  describe "#__mod_id" do
    it "returns the current __mod_id" do
      expect(test_class.new.__mod_id).to eq(nil)
    end
  end

  describe "#__mod_id=" do
    it "sets the current mod_id" do
      instance = test_class.new
      instance.__mod_id = 1
      expect(instance.mod_id).to eq(1)
    end
  end

  describe "#mod_id" do
    it "is an alias of #__mod_id" do
      expect(test_class.instance_method(:mod_id)).to eq(test_class.instance_method(:__mod_id))
    end
  end

  describe "#inspect" do
    it "returns a string representing the record class with id and attributes" do
      allow(test_class).to receive(:to_s).and_return("TestClass")
      instance = test_class.new(__record_id: 1, foo: "F00")
      expect(instance.inspect).to eq(%{#<TestClass(layout: TestClass) record_id: 1 foo: "F00", bar: nil>})
    end
  end

  describe "#persisted?" do
    it "returns true if the record has a __record_id set" do
      expect(test_class.new(__record_id: 1).persisted?).to eq(true)
    end

    it "returns false if the record has no __record_id set" do
      expect(test_class.new.persisted?).to eq(false)
    end
  end

  describe ".destroy" do
    xit "destroys the record with the given record id"
  end
end
