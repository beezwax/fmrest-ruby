require "spec_helper"

RSpec.describe FmData::Spyke::Base do
  it "inherits from Spyke::Base" do
    expect(FmData::Spyke::Base.superclass).to eq(Spyke::Base)
  end

  it "includes FmData::Spyke::Model" do
    expect(FmData::Spyke::Base.included_modules).to include(FmData::Spyke::Model)
  end

  describe "method form" do
    let(:subclass) { FmData::Spyke::Base(host: "example.com") }

    it "creates a subclass of FmData::Spyke::Base" do
      expect(subclass.superclass).to eq(FmData::Spyke::Base)
    end

    it "takes an argument and assigns it to fmdata_config" do
      expect(subclass.fmdata_config).to eq(host: "example.com")
    end
  end
end
