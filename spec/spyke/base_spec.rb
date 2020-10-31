# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::Spyke::Base do
  it "inherits from Spyke::Base" do
    expect(FmRest::Spyke::Base.superclass).to eq(Spyke::Base)
  end

  it "includes FmRest::Spyke::Model" do
    expect(FmRest::Spyke::Base.included_modules).to include(FmRest::Spyke::Model)
  end
end
