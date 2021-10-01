require "spec_helper"

RSpec.describe FmRest::V1 do
  it "is extended with FmRest::V1::Connection" do
    expect(FmRest::V1.singleton_class).to include(FmRest::V1::Connection)
  end

  it "is extended with FmRest::V1::Paths" do
    expect(FmRest::V1.singleton_class).to include(FmRest::V1::Paths)
  end

  it "is extended with FmRest::V1::ContainerFields" do
    expect(FmRest::V1.singleton_class).to include(FmRest::V1::ContainerFields)
  end

  it "is extended with FmRest::V1::Utils" do
    expect(FmRest::V1.singleton_class).to include(FmRest::V1::Utils)
  end
end
