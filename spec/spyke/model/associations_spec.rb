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
                  PiratesTable: [
                    {
                      "Pirate::name": "Hendrick van der Decken",
                      "Pirate::rank": "Captain",
                      recordId: "1",
                      modId: "0"
                    },

                    {
                      "Pirate::name": "Marthijn van het Vriesendijks",
                      "Pirate::rank": "First Officer",
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
          expect(ship.crew.first.mod_id).to eq("0")
          expect(ship.crew.first).to_not be_changed
          expect(ship.crew.last.record_id).to eq(2)
        end
      end
    end
  end
end
