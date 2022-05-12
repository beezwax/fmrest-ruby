# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::V1 do
  it { expect(FmRest::V1.singleton_class).to include(FmRest::V1::Connection) }
  it { expect(FmRest::V1.singleton_class).to include(FmRest::V1::Paths) }
  it { expect(FmRest::V1.singleton_class).to include(FmRest::V1::ContainerFields) }
  it { expect(FmRest::V1.singleton_class).to include(FmRest::V1::Utils) }
end
