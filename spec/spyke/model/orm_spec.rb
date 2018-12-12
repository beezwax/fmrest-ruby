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

  [:limit, :offset, :sort, :query, :portal].each do |delegator|
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

      it "applies portal URI param" do
        request = stub_request(:post, fm_url(layout: "Ships") + "/_find")
          .with(body: hash_including(portal: ["PiratesTable", "Flags"]))
          .to_return_fm
        Ship.query(name: "Mary Celeste").portal(:crew, "Flags").fetch
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

  describe "#save" do
    let(:ship) { Ship.new }

    before do
      stub_session_login
    end

    context "with failed validations" do
      before do
        allow(ship).to receive(:valid?).and_return(false)

        stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_fm({ recordId: 1, modId: 1 })
      end

      it "returns false when called with no options" do
        expect(ship.save).to eq(false)
      end

      it "returns true if successfully saved when called with validate: false" do
        expect(ship.save(validate: false)).to eq(true)
      end
    end

    context "with passing validations" do
      before do
        allow(ship).to receive(:valid?).and_return(true)
      end

      context "when the server responds successfully" do
        before do
          stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_fm({ recordId: 1, modId: 1 })
        end

        it "returns true" do
          expect(ship.save).to eq(true)
        end
      end

      context "when the server responds with failure" do
        before do
          stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_fm(false)
        end

        it "returns false" do
          expect(ship.save).to eq(false)
        end
      end
    end
  end
end

