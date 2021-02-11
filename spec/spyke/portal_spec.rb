# frozen_string_literal: true

require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Portal do
  describe "#portal_key" do
    it "defaults to the association name" do
      klass = fmrest_spyke_class do
        has_portal :pirates, class_name: "Pirate"
      end

      expect(klass.new.pirates.portal_key).to eq("pirates")
    end

    it "returns the :portal_key if given to has_portal" do
      klass = fmrest_spyke_class do
        has_portal :pirates, portal_key: "F00", class_name: "Pirate"
      end

      expect(klass.new.pirates.portal_key).to eq("F00")
    end
  end

  describe "#attribute_prefix" do
    it "defaults to the portal_key" do
      klass = fmrest_spyke_class do
        has_portal :pirates, portal_key: "F00", class_name: "Pirate"
      end

      expect(klass.new.pirates.attribute_prefix).to eq("F00")
    end

    it "returns the :attribute_prefix if given to has_portal" do
      klass = fmrest_spyke_class do
        has_portal :pirates, attribute_prefix: "Bar", class_name: "Pirate"
      end

      expect(klass.new.pirates.attribute_prefix).to eq("Bar")
    end
  end

  describe "#parent_changes_applied" do
    it "signals changes applied to all portal records" do
      klass = fmrest_spyke_class do
        has_portal :pirates, class_name: "Pirate"
      end

      instance = klass.new
      instance.pirates.build
      instance.pirates.build

      expect(instance.pirates.first).to receive(:changes_applied).once
      expect(instance.pirates.last).to receive(:changes_applied).once

      instance.pirates.parent_changes_applied
    end
  end

  describe "#<<" do
    let(:klass) {
      klass = fmrest_spyke_class do
        has_portal :pirates, class_name: "Pirate"
      end
    }

    it "raises an error if the given record doesn't match the association class" do
      expect { klass.new.pirates << 1 }.to raise_error(ArgumentError, /^Expected an instance of Pirate/)
    end

    it "adds the record to the association" do
      pirate = Pirate.new

      instance = klass.new
      instance.pirates << pirate

      expect(instance.pirates.first).to be(pirate)
    end

    it "marks the record as embedded" do
      pirate = Pirate.new
      klass.new.pirates << pirate

      expect(pirate.embedded_in_portal?).to eq(true)
    end

    it "returns self" do
      host = klass.new

      expect(host.pirates << Pirate.new).to be(host.pirates)
    end

    it "is aliased as #push" do
      expect(described_class.instance_method(:push)).to eq(described_class.instance_method(:<<))
    end

    it "is aliased as #concat" do
      expect(described_class.instance_method(:concat)).to eq(described_class.instance_method(:<<))
    end
  end

  describe "#_remove_marked_for_destruction" do
    it "prunes the association" do
      klass = fmrest_spyke_class do
        has_portal :pirates, class_name: "Pirate"
      end

      host = klass.new
      pirate = Pirate.new
      host.pirates << [pirate, Pirate.new]

      pirate.mark_for_destruction

      expect { host.pirates._remove_marked_for_destruction }.to \
        change { host.pirates.count }.from(2).to(1)
    end
  end
end
