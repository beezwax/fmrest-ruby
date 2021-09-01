# frozen_string_literal: true

require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::Associations do
  describe ".portal_options" do
    it "defaults to an empty frozen hash" do
      klass = fmrest_spyke_class
      expect(klass.portal_options).to eq({})
      expect(klass.portal_options).to be_frozen
    end
  end

  describe ".has_portal" do
    it "creates a Portal instance association" do
      expect(Ship.new.crew).to be_a(FmRest::Spyke::Portal)
    end

    it "finds the associated class based on the given class_name" do
      expect(Ship.new.crew.klass).to be(Pirate)
    end
  end

  describe "association reader methods" do
    context "when the association is a portal" do
      it "returns the same association instance each time it's called" do
        ship = Ship.new
        expect(ship.crew.object_id).to eq(ship.crew.object_id)
      end

      context "loading a record with portal data" do
        before do
          stub_session_login

          stub_request(:get, fm_url(layout: "Ships", id: 1)).to_return_fm(
            data: [
              {
                fieldData: {
                  name: "De Vliegende Hollander"
                },

                portalData: {
                  PiratesPortal: [
                    {
                      "Pirate::Name": "Hendrick van der Decken",
                      "Pirate::Rank": "Captain",
                      recordId: "1",
                      modId: "0"
                    },

                    {
                      "Pirate::Name": "Marthijn van het Vriesendijks",
                      "Pirate::Rank": "First Officer",
                      recordId: "2",
                      modId: "0"
                    }
                  ]
                },

                recordId: "1",
                modId: "0"
              }
            ]
          )
        end

        it "initializes the portal's associated records" do
          ship = Ship.find(1)

          expect(ship.crew.size).to eq(2)
          expect(ship.crew.first).to be_a(Pirate)
          expect(ship.crew.first.name).to eq("Hendrick van der Decken")
          expect(ship.crew.first.record_id).to eq(1)
          expect(ship.crew.first.mod_id).to eq(0)
          expect(ship.crew.first).to_not be_changed
          expect(ship.crew.last.record_id).to eq(2)
        end
      end
    end
  end

  describe "#portals" do
    it "returns the record's portal associations" do
      ship = Ship.new
      expect(ship.portals).to eq([ship.crew, ship.cabins])
    end
  end

  describe "#marked_for_destruction" do
    it "sets the marked_for_destruction flag" do
      ship = Ship.new
      expect { ship.mark_for_destruction }.to change { ship.marked_for_destruction? }.from(false).to(true)
    end
  end

  describe "#embedded_in_portal" do
    it "sets the embedded_in_portal flag" do
      ship = Ship.new
      expect { ship.embedded_in_portal }.to change { ship.embedded_in_portal? }.from(false).to(true)
    end
  end

  describe "#changed? with portal awareness" do
    it "is true if embedded_in_portal? is true" do
      ship = Ship.new
      expect { ship.embedded_in_portal }.to change { ship.changed? }.from(false).to(true)
    end
  end

  describe "#changes_applied with portal awareness" do
    it "resets embedded_in_portal and marked_for_destruction flags" do
      ship = Ship.new
      ship.embedded_in_portal
      ship.mark_for_destruction
      ship.changes_applied
      expect(ship.embedded_in_portal?).to eq(false)
      expect(ship.marked_for_destruction?).to eq(false)
    end
  end

  describe "#__new_portal_record_info=" do
    it "sequentially applies record_ids and mod_ids to new portal records" do
      ship = Ship.new
      ship.crew.build(name: "Luffy")
      ship.crew.build(name: "Hook")

      ship.__new_portal_record_info = [tableName: "PiratesPortal", recordId: 5]

      expect(ship.crew[0].__record_id).to eq(4)
      expect(ship.crew[1].__record_id).to eq(5)
    end
  end

  describe "after save: remove_marked_for_destruction" do
    it "removes portal records marked for destruction" do
      stub_session_login
      stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_fm

      ship = Ship.new
      ship.crew.build(name: "Luffy")
      ship.crew.build(name: "Hook")

      ship.crew.first.mark_for_destruction

      ship.save

      expect(ship.crew.count).to eq(1)
      expect(ship.crew.first.name).to eq("Hook")
    end
  end
end
