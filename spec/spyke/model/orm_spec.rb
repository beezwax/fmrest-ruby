require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::Orm do
  let :test_class do
    fmrest_spyke_class do
      attributes foo: "Foo", bar: "Bar"
    end
  end

  describe "class attributes" do
    [:default_limit, :default_sort].each do |attr|
      describe attr do
        it "creates the class methods" do
          expect(test_class).to respond_to(attr)
          expect(test_class).to respond_to("#{attr}=")
        end

        it "doesn't create the instance methods" do
          instance = test_class.new
          expect(instance).to_not respond_to(attr)
          expect(instance).to_not respond_to("#{attr}=")
        end

        it "doesn't create the predicate method" do
          expect(test_class).to_not respond_to("#{attr}?")
        end
      end
    end
  end

  describe ".all" do
    it "returns a FmRest::Spyke::Relation" do
      expect(Ship.all).to be_a(::FmRest::Spyke::Relation)
    end
  end

  [:limit, :offset, :sort, :order, :query, :omit, :portal, :portals, :includes, :without_portals, :with_all_portals].each do |delegator|
    describe ".#{delegator}" do
      let(:scope) { double("Relation") }

      it "delegates to all" do
        allow(test_class).to receive(:all).and_return(scope)
        expect(scope).to receive(delegator)
        test_class.send(delegator)
      end
    end
  end

  describe ".fetch" do
    before { stub_session_login }

    context "when a query is present in current scope" do
      let(:request) { stub_request(:post, fm_url(layout: "Pirates") + "/_find").to_return_fm }

      it "applies limit JSON param" do
        request.with(body: { limit: 42, query: [{ name: "foo" }] })
        Pirate.query(name: "foo").limit(42).fetch
        expect(request).to have_been_requested
      end

      it "applies offset JSON param" do
        request.with(body: { offset: 10, query: [{ name: "foo" }] })
        Pirate.query(name: "foo").offset(10).fetch
        expect(request).to have_been_requested
      end

      it "applies sort JSON param" do
        request.with(body: { sort: [{fieldName: "name"}, {fieldName: "rank", sortOrder: "descend"}], query: [{ name: "foo" }] })
        Pirate.query(name: "foo").sort(:name, :rank!).fetch
        expect(request).to have_been_requested
      end

      it "applies sort JSON param even when .limit(1) is used" do
        request.with(body: { limit: 1, sort: [{fieldName: "name"}, {fieldName: "rank", sortOrder: "descend"}], query: [{ name: "foo" }] })
        Pirate.query(name: "foo").limit(1).sort(:name, :rank!).fetch
        expect(request).to have_been_requested
      end

      it "applies portal URI param" do
        request = stub_request(:post, fm_url(layout: "Ships") + "/_find")
          .with(body: hash_including(portal: ["PiratesTable", "Flags"]))
          .to_return_fm
        Ship.query(name: "Mary Celeste").portal(:crew, "Flags").fetch
        expect(request).to have_been_requested
      end

      it "applies no portal URI param when portal(true) was called" do
        request = stub_request(:post, fm_url(layout: "Ships") + "/_find")
          .with(body: { query: [{ name: "Mary Celeste" }] })
          .to_return_fm
        Ship.query(name: "Mary Celeste").portal(true).fetch
        expect(request).to have_been_requested
      end

      it "applies empty portal URI param" do
        request = stub_request(:post, fm_url(layout: "Ships") + "/_find")
          .with(body: hash_including(portal: []))
          .to_return_fm
        Ship.query(name: "Mary Celeste").portal(false).fetch
        expect(request).to have_been_requested
      end

      it "applies portal limit param" do
        request = stub_request(:post, fm_url(layout: "Ships") + "/_find")
         .with(
           body: { portal: ["PiratesTable", "Flags"], "limit.PiratesTable" => 10, query: [{ name: "Mary Celeste" }] },
         ).to_return_fm
        Ship.query(name: "Mary Celeste").portal(:crew, "Flags").limit(crew: 10).fetch
        expect(request).to have_been_requested
      end

      it "applies portal offset param" do
        request = stub_request(:post, fm_url(layout: "Ships") + "/_find")
         .with(
           body: { portal: ["PiratesTable", "Flags"], "offset.PiratesTable" => 10, query: [{ name: "Mary Celeste" }] },
         ).to_return_fm
        Ship.query(name: "Mary Celeste").portal(:crew, "Flags").offset(crew: 10).fetch
        expect(request).to have_been_requested
      end

      it "applies both portal offset and limit params" do
        request = stub_request(:post, fm_url(layout: "Ships") + "/_find")
         .with(
           body: { portal: ["PiratesTable", "Flags"], "offset.PiratesTable" => 10,  "limit.PiratesTable" => 10, query: [{ name: "Mary Celeste" }] },
         ).to_return_fm
        Ship.query(name: "Mary Celeste").portal(:crew, "Flags").offset(crew: 10).limit(crew: 10).fetch
        expect(request).to have_been_requested
      end

      it "applies all combined JSON params" do
        request.with(body: {
          limit:  42,
          offset: 10,
          sort:   [{fieldName: "name"}, {fieldName: "rank", sortOrder: "descend"}],
          query:  [{ name: "foo" }]
        })
        Pirate.limit(42).offset(10).sort(:name, :rank!).query(name: "foo").fetch
        expect(request).to have_been_requested
      end

      context "when the request returns a 401 API error" do
        let(:request) { stub_request(:post, fm_url(layout: "Pirates") + "/_find").to_return_fm(401) }

        it "returns an empty Spyke::Result" do
          request.with(body: { query: [{ name: "foo" }] })
          expect(Pirate.query(name: "foo").fetch.data).to eq(nil)
        end

        it "raises an error if the model's raise_on_no_matching_records is true" do
          request.with(body: { query: [{ name: "foo" }] })
          Pirate.raise_on_no_matching_records = true
          expect { Pirate.query(name: "foo").fetch }.to raise_error(FmRest::APIError::NoMatchingRecordsError)
          Pirate.raise_on_no_matching_records = nil
        end
      end
    end

    context "when no query is present in current scope" do
      let(:request) { stub_request(:get, fm_url(layout: "Pirates") + "/records").to_return_fm }

      it "applies _limit URI param" do
        request.with(query: { _limit: 42 })
        Pirate.limit(42).fetch
        expect(request).to have_been_requested
      end

      it "applies _offset URI param" do
        request.with(query: { _offset: 10 })
        Pirate.offset(10).fetch
        expect(request).to have_been_requested
      end

      it "applies _sort URI param" do
        request.with(query: { _sort: [{fieldName: "name"}, {fieldName: "rank", sortOrder: "descend"}].to_json })
        Pirate.sort(:name, :rank!).fetch
        expect(request).to have_been_requested
      end

      it "applies portal URI param" do
        request = stub_request(:get, fm_url(layout: "Ships") + "/records")
          .with(query: { portal: ["PiratesTable", "Flags"].to_json })
          .to_return_fm
        Ship.portal(:crew, "Flags").fetch
        expect(request).to have_been_requested
      end

      it "applies empty portal URI param" do
        request = stub_request(:get, fm_url(layout: "Ships") + "/records")
          .with(query: { portal: "[]" })
          .to_return_fm
        Ship.portal(false).fetch
        expect(request).to have_been_requested
      end

      it "applies portal limit param" do
        request = stub_request(:get, fm_url(layout: "Ships") + "/records")
          .with(query: { portal: ["PiratesTable", "Flags"].to_json, "_limit.PiratesTable" => 10 })
          .to_return_fm
        Ship.portal(:crew, "Flags").limit(crew: 10).fetch
        expect(request).to have_been_requested
      end

      it "applies portal offset param" do
        request = stub_request(:get, fm_url(layout: "Ships") + "/records")
          .with(query: { portal: ["PiratesTable"].to_json, "_offset.PiratesTable" => 10 })
          .to_return_fm
        Ship.portal(:crew).offset(crew: 10).fetch
        expect(request).to have_been_requested
      end

      it "applies both portal offset and limit params" do
        request = stub_request(:get, fm_url(layout: "Ships") + "/records")
          .with(query: {
            portal: ["PiratesTable"].to_json,
            "_offset.PiratesTable" => 10,
            "_limit.PiratesTable" => 10
          })
          .to_return_fm
        Ship.portal(:crew).offset(crew: 10).limit(crew: 10).fetch
        expect(request).to have_been_requested
      end

      it "applies all combined URI params" do
        request.with(query: {
          _limit:  42,
          _offset: 10,
          _sort:   [{fieldName: "name"}, {fieldName: "rank", sortOrder: "descend"}].to_json,
        })
        Pirate.limit(42).offset(10).sort(:name, :rank!).fetch
        expect(request).to have_been_requested
      end
    end

    it "preserves current_scope" do
      stub_request(:get, fm_url(layout: "Pirates") + "/records").with(query: hash_including({})).to_return_fm
      scope = Pirate.limit(42).offset(10).sort(:name, :rank!)
      expect { scope.fetch }.to_not change { Pirate.current_scope }
    end
  end

  describe "#save!" do
    let(:ship) { Ship.new }

    before { stub_session_login }

    context "with failed validations" do
      before do
        allow(ship).to receive(:valid?).and_return(false)

        stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_fm(recordId: "1", modId: "1")
      end

      it "raises ActiveModel::ValidationError when called with no options" do
        expect { ship.save! }.to raise_error(ActiveModel::ValidationError)
      end

      it "returns true if successfully saved when called with validate: false" do
        expect(ship.save!(validate: false)).to eq(true)
      end
    end

    context "with passing validations" do
      before do
        allow(ship).to receive(:valid?).and_return(true)
      end

      context "when the server responds successfully" do
        before do
          stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_fm(recordId: "1", modId: "1")
        end

        it "returns true" do
          expect(ship.save!).to eq(true)
        end
      end

      context "when the server responds with a validation error" do
        before do
          stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_json(
            response: {},
            messages: [{ code: 500, message: "Date validation error"}]
          )
        end

        it "raises an APIError::ValidationError" do
          expect { ship.save! }.to raise_error(FmRest::APIError::ValidationError)
        end
      end
    end
  end

  describe "#save" do
    let(:ship) { Ship.new name: "Mary Celeste" }

    before { stub_session_login }

    context "with passing validations" do
      before do
        allow(ship).to receive(:valid?).and_return(true)
      end

      context "when the server responds with a validation error" do
        before do
          stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_json(
            response: {},
            messages: [{ code: 500, message: "Date validation error"}]
          )
        end

        it "returns false" do
          expect(ship.save).to eq(false)
        end
      end
    end

    context "with a successful save" do
      before do
        stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_fm(
          recordId: "1",
          modId: "0"
        )
      end

      it "resets changes information for self and portal records" do
        expect { ship.save }.to change { ship.changed? }.from(true).to(false)
      end
    end

    context "with an unsuccessful save (server side validation error)" do
      before do
        stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_json(
          response: {},
          messages: [{ code: 500, message: "Date validation error"}]
        )
      end

      it "doesn't resets changes information" do
        expect { ship.save }.to_not change { ship.changed? }.from(true)
      end
    end
  end

  describe "#reload" do
    let(:ship) { Ship.new(id: 1) }

    before { stub_session_login }

    before do
      stub_request(:get, fm_url(layout: "Ships") + "/records/1").to_return_fm(
        data: [{ recordId: "1", modId: "2", fieldData: { name: "Obra Dinn Reloaded" } }]
      )
    end

    it "reloads the record" do
      expect { ship.reload }.to change { ship.name }.to("Obra Dinn Reloaded")
    end

    it "sets the mod_id" do
      expect { ship.reload }.to change { ship.mod_id }.from(nil).to("2")
    end
  end

  describe "#update!" do
    let(:ship) { Ship.new }

    it "calls #save! instead of #save" do
      expect(ship).to_not receive(:save)
      expect(ship).to receive(:save!).and_return(true)
      ship.update!({})
    end
  end

  describe ".create!" do
    it "calls #save! instead of #save" do
      expect_any_instance_of(Ship).to_not receive(:save)
      expect_any_instance_of(Ship).to receive(:save!).and_return(true)
      Ship.create!({})
    end
  end

  describe "#execute_script" do
    before { stub_session_login }

    it "runs the script indicated" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/clear_data").to_return_fm

      Ship.execute_script("clear_data")

      expect(request).to have_been_requested
    end

    it "raises error when script is missing" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/bleh").to_return_fm(
        104
      )

      expect { Ship.execute_script("bleh") }.to raise_error(FmRest::APIError::ResourceMissingError)
    end

    it "sends along any passed parameters" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/clear_data?script.param=some%20string").to_return_fm

      Ship.execute_script("clear_data", param: "some string")

      expect(request).to have_been_requested
    end
  end
end

