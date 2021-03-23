# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::Spyke::Base do
  it "inherits from Spyke::Base" do
    expect(FmRest::Spyke::Base.superclass).to eq(Spyke::Base)
  end

  it "includes FmRest::Spyke::Model" do
    expect(FmRest::Spyke::Base.included_modules).to include(FmRest::Spyke::Model)
  end

  it "is aliased as FmRest::Layout" do
    expect(FmRest::Layout).to equal(described_class)
  end

  describe ".Layout" do
    it "creates a subclass of FmRest::Spyke::Base with the layout already set" do
      klass = FmRest::Layout("TestLayout")
      expect(klass.ancestors[1]).to eq(described_class)
      expect(klass.layout).to eq("TestLayout")
    end
  end
end
