# frozen_string_literal: true

require "spec_helper"
require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::URI do
  let :test_class do
    fmrest_spyke_class
  end

  describe ".layout" do
    it "when called with no args for first time on the class returns the class name" do
      expect(test_class.layout).to eq("TestClass")
    end

    it "when called with an arg sets the layout" do
      test_class.layout :DifferentLayout
      expect(test_class.layout).to eq(:DifferentLayout)
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
