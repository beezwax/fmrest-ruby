require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Relation do
  let(:test_class) do
    fmrest_spyke_class do
      attributes :foo, :bar

      has_portal :bridges, portal_key: "Bridges"
      has_portal :tunnels, portal_key: "Tunnels"
    end
  end

  let(:relation) { FmRest::Spyke::Relation.new(test_class) }

  describe "#initialize" do
    it "sets the default limit if any" do
      test_class.default_limit = 9876
      expect(relation.limit_value).to eq(9876)
    end

    it "sets the default sort if any" do
      test_class.default_sort = [:foo, :bar]
      expect(relation.sort_params).to eq([{ fieldName: :foo }, { fieldName: :bar }])
    end
  end

  describe "#limit" do
    it "creates a new scope with the given limit" do
      limit_scope = relation.limit(1010)
      expect(limit_scope).to_not eq(relation)
      expect(limit_scope).to be_a(FmRest::Spyke::Relation)
      expect(limit_scope.limit_value).to eq(1010)
    end

    context "when given portal limits" do
      it "applies the limit to the params for each portal key" do
        limit_scope = relation.limit(bridges: 10, tunnels: 1)
        expect(limit_scope.portal_params).to eq("limit.Bridges"=>10, "limit.Tunnels"=>1)
      end

      it "doesn't modify the portal_params of the parent relation" do
        expect { relation.limit(bridges: 10) }.to_not change { relation.portal_params }
      end
    end
  end

  describe "#offset" do
    it "creates a new scope with the given offset" do
      offset_scope = relation.offset(22)
      expect(offset_scope).to_not eq(relation)
      expect(offset_scope).to be_a(FmRest::Spyke::Relation)
      expect(offset_scope.offset_value).to eq(22)
    end

    context "when given portal offsets" do
      it "applies the offset to the params for each portal key" do
        offset_scope = relation.offset(bridges: 10, tunnels: 1)
        expect(offset_scope.portal_params).to eq("offset.Bridges"=>10, "offset.Tunnels"=>1)
      end

      it "doesn't modify the portal_params of the parent relation" do
        expect { relation.limit(bridges: 10) }.to_not change { relation.portal_params }
      end
    end
  end

  describe "#sort" do
    context "when given defined attributes as symbols or strings" do
      it "creates a new scope with the given sort params" do
        sort_scope = relation.sort(:foo, [:bar!, :bar__desc], :bar__descend)
        expect(sort_scope).to_not eq(relation)
        expect(sort_scope).to be_a(FmRest::Spyke::Relation)
        expect(sort_scope.sort_params).to \
          eq([{ fieldName: :foo },
              { fieldName: :bar, sortOrder: "descend" },
              { fieldName: :bar, sortOrder: "descend" },
              { fieldName: :bar, sortOrder: "descend" }])
      end
    end

    context "when given undefined attributes as symbols or strings" do
      it do
        expect { relation.sort(:not_an_attribute) }.to raise_error(ArgumentError)
        expect { relation.sort("NotAnAttribute") }.to raise_error(ArgumentError)
      end
    end

    it "doesn't modify the sort_params of the parent relation" do
      expect { relation.sort(:foo) }.to_not change { relation.sort_params }
    end
  end

  describe "#order" do
    it "is an alias for #sort" do
      expect(FmRest::Spyke::Relation.instance_method(:order)).to eq(FmRest::Spyke::Relation.instance_method(:sort))
    end
  end

  describe "#portal" do
    it "raises ArgumentError when given no arguments" do
      expect { relation.portal }.to raise_error(ArgumentError, "Call `portal' with at least one argument")
    end

    it "raises ArgumentError when given undefined portals as symbols" do
      expect { relation.portal(:not_a_portal) }.to raise_error(ArgumentError)
    end

    context "when given defined portals as symbols or undefined portals as strings" do
      it "creates a new scope with the given portal params" do
        portal_scope = relation.portal(:bridges, [:tunnels, :tunnels]).portal("SirNotAppearingInThisClass")
        expect(portal_scope).to_not eq(relation)
        expect(portal_scope).to be_a(FmRest::Spyke::Relation)
        expect(portal_scope.included_portals).to eq(["Bridges", "Tunnels", "SirNotAppearingInThisClass"])
      end
    end

    it "sets included_portals to nil when given true" do
      portal_scope = relation.portal(true)
      expect(portal_scope.included_portals).to eq(nil)
    end

    it "sets included_portals to [] when given false" do
      portal_scope = relation.portal(false)
      expect(portal_scope.included_portals).to eq([])
    end

    it "doesn't modify the included_portals of the parent relation" do
      expect { relation.portal(:bridges) }.to_not change { relation.included_portals }
    end
  end

  describe "#with_all_portals" do
    it "sets included_portals to nil" do
      portal_scope = relation.with_all_portals
      expect(portal_scope.included_portals).to eq(nil)
    end
  end

  describe "#without_portals" do
    it "sets included_portals to []" do
      portal_scope = relation.without_portals
      expect(portal_scope.included_portals).to eq([])
    end
  end

  describe "#portals" do
    it "is an alias for #portal" do
      expect(FmRest::Spyke::Relation.instance_method(:portals)).to eq(FmRest::Spyke::Relation.instance_method(:portal))
    end
  end

  describe "#includes" do
    it "is an alias for #portal" do
      expect(FmRest::Spyke::Relation.instance_method(:includes)).to eq(FmRest::Spyke::Relation.instance_method(:portal))
    end
  end

  describe "#query" do
    it "creates a new scope with the given query params merged with previous ones" do
      query_scope = relation.query(foo: "Noodles").query(bar: "Onions", omit: true)
      expect(query_scope).to_not eq(relation)
      expect(query_scope).to be_a(FmRest::Spyke::Relation)
      expect(query_scope.query_params).to eq([{ "foo" => "Noodles" }, { "bar" => "Onions", "omit" => "true" }])
    end
  end

  describe "#omit" do
    it "forwards params to #query with omit: true" do
      expect(relation).to receive(:query).with(foo: "Coffee", omit: true).and_return("Yipee!")
      expect(relation.omit(foo: "Coffee")).to eq("Yipee!")
    end
  end

  describe "#has_query?" do
    it "returns false if there's no query set" do
      expect(relation.has_query?).to eq(false)
    end

    it "returns true if there's a query set" do
      new_relation = relation.query(foo: "Croissant")
      expect(new_relation.has_query?).to eq(true)
    end
  end

  describe "#find_one" do
    # TODO: Make these specs less attached to the implementation
    context "when the id is not set" do
      it "runs a fetch with limit 1 and returns the first element" do
        other_relation = FmRest::Spyke::Relation.new(test_class)
        fetch_result, record = double, double
        expect(relation).to receive(:limit).with(1).and_return(other_relation)
        expect(other_relation).to receive(:fetch).and_return(fetch_result)
        expect(test_class).to receive(:new_collection_from_result).with(fetch_result).and_return([record])
        expect(relation.find_one).to eq(record)
      end

      it "memoizes the result" do
        other_relation, fetch_result, record = double, double, double
        allow(relation).to receive(:limit).and_return(other_relation)
        allow(other_relation).to receive(:fetch)
        allow(test_class).to receive(:new_collection_from_result).and_return([record])
        expect { relation.find_one }.to change { relation.instance_variable_get(:@find_one) }.from(nil).to(record)
        expect(relation.find_one).to equal(relation.instance_variable_get(:@find_one))
      end
    end

    context "when the primary key is set" do
      let(:scope) { relation.limit(10).offset(1).sort(:foo).query(foo: 1).where(id: 1) }

      it "ignores collection parameters and doesn't set limit = 1" do
        expect(scope).to receive(:without_collection_params)
        expect(scope).to_not receive(:limit)
        scope.find_one
      end

      it "calls fetch and returns its resulting record" do
        record = double
        allow(test_class).to receive(:new_instance_from_result).and_return(record)
        expect(scope).to receive(:fetch)
        expect(scope.find_one).to eq(record)
      end

      it "memoizes the result" do
        record = double
        allow(test_class).to receive(:new_instance_from_result).and_return(record)
        allow(scope).to receive(:fetch)
        expect { scope.find_one }.to change { scope.instance_variable_get(:@find_one) }.from(nil).to(record)
      end
    end
  end

  # TODO: Testing private methods is generally considered bad practice, but
  # this was the most straight-forward way I could find of testing the special
  # case in #find_one where the primary key is set. We need a better way of
  # testing this.
  describe "(private) #without_collection_params" do
    it "clears limit, offset, sort and query, and restores it after yielding" do
      scope = relation.limit(10).offset(10).query(foo: 1).sort(:foo)

      scope.send(:without_collection_params) do
        expect(scope.limit_value).to eq(nil)
        expect(scope.offset_value).to eq(nil)
        expect(scope.sort_params).to eq(nil)
        expect(scope.query_params).to eq(nil)
      end

      expect(scope.limit_value).to eq(10)
      expect(scope.offset_value).to eq(10)
      expect(scope.sort_params).to eq([{fieldName: :foo}])
      expect(scope.query_params).to eq([{"foo" => 1}])
    end
  end
end
