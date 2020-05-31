require "spec_helper"

RSpec.describe FmRest::Spyke::Base do
  it "inherits from Spyke::Base" do
    expect(FmRest::Spyke::Base.superclass).to eq(Spyke::Base)
  end

  it "includes FmRest::Spyke::Model" do
    expect(FmRest::Spyke::Base.included_modules).to include(FmRest::Spyke::Model)
  end

  describe "method form" do
    context "with config given" do
      let(:subclass) { FmRest::Spyke::Base(host: "example.com") }

      it "creates a subclass of FmRest::Spyke::Base" do
        expect(subclass.superclass).to eq(::FmRest::Spyke::Base)
      end

      it "takes an argument and assigns it to fmrest_config" do
        expect(subclass.fmrest_config).to eq(host: "example.com")
      end
    end

    context "with no config given" do
      let(:subclass) { FmRest::Spyke::Base() }

      it "returns FmRest::Spyke::Base" do
        expect(subclass).to eq(::FmRest::Spyke::Base)
      end

      it "doesn't set fmrest_config" do
        expect(subclass.fmrest_config).to eq(FmRest.default_connection_settings)
      end
    end
  end
end
