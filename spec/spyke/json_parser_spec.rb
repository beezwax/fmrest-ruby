require "spec_helper"

RSpec.describe FmRest::Spyke::JsonParser do
  context "when requesting a single record by id" do
    xit "returns a hash with single record data"
  end

  context "when requesting a collection through the find API" do
    xit "returns a hash with collection data"
  end

  context "when saving a record" do
    context "when sucessful" do
      xit "returns a hash with single record data"
    end

    context "when unsucessful" do
      xit "returns a hash with validation errors"
    end
  end
end
