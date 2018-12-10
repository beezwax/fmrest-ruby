require "spec_helper"

RSpec.describe FmData::Spyke::Model do
  let(:test_class) { fmdata_spyke_class }

  it "defines mod_id accessor" do
    instance = test_class.new
    expect(instance).to respond_to(:mod_id)
    expect(instance).to respond_to(:mod_id=)
  end
end
