# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::Spyke::PortalBuilder do
  describe "#klass" do
    it "defaults to FmRest::Layout" do
      test_class = fmrest_spyke_class do
        has_portal :no_class_portal
      end

      expect(test_class.associations[:no_class_portal].klass).to eq(FmRest::Layout)
    end
  end
end
