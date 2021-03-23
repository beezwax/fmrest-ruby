# frozen_string_literal: true

require "spec_helper"
require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::URI do
  let :test_class do
    fmrest_spyke_class
  end

  describe ".layout" do
    it "defaults to the class name" do
      expect(test_class.layout).to eq("TestClass")
    end

    it "when called with an arg sets the layout, converted to a frozen string" do
      test_class.layout :DifferentLayout
      expect(test_class.layout).to eq("DifferentLayout")
      expect(test_class.layout).to be_frozen
    end

    it "is inheritable" do
      test_class.layout :TestLayout

      subclass = Class.new(test_class)
      expect(subclass.layout).to eq("TestLayout")

      subclass.layout :NewTestLayout
      expect(test_class.layout).to eq("TestLayout")
      expect(subclass.layout).to eq("NewTestLayout")
    end
  end

  describe ".uri" do
    it "when called without args and a set layout it returns the FM Data URI" do
      expect(test_class.uri).to eq("layouts/TestClass/records(/:__record_id)")
    end

    it "when called with an arg it sets the URI" do
      test_class.uri "foo/bar"
      expect(test_class.uri).to eq("foo/bar")
    end
  end
end
