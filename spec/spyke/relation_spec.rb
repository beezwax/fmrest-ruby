# frozen_string_literal: true

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Relation do
  let(:test_class) do
    fmrest_spyke_class do
      attributes :foo, :bar

      has_portal :ships, portal_key: "Ships"
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
      expect(relation.sort_params).to eq([{ fieldName: "foo" }, { fieldName: "bar" }])
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
          eq([{ fieldName: "foo" },
              { fieldName: "bar", sortOrder: "descend" },
              { fieldName: "bar", sortOrder: "descend" },
              { fieldName: "bar", sortOrder: "descend" }])
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

  describe "#script" do
    context "when given a hash with script options" do
      it "creates a new scope with the given script options" do
        script_scope = relation.script(after: ["script", "param"], presort: ["script", "param"], prerequest: ["script", "param"])

        expect(script_scope).to_not eq(relation)
        expect(script_scope).to be_a(FmRest::Spyke::Relation)
        expect(script_scope.script_params).to eq(
          script: "script",
          "script.param": "param",
          "script.presort": "script",
          "script.presort.param": "param",
          "script.prerequest": "script",
          "script.prerequest.param": "param"
        )
      end
    end

    context "when chained" do
      it "merges script options together" do
        script_scope = relation.script(after: "after").script(presort: "presort")
        expect(script_scope.script_params).to eq(
          script: "after",
          "script.presort": "presort"
        )
      end
    end

    context "when given nil or false" do
      it "creates a new scope with empty script params" do
        relation.script_params = { test: "foo" }
        expect(relation.script(nil).script_params).to eq({})
        expect(relation.script(false).script_params).to eq({})
      end
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
    context "when there is a key/value collision" do
      it "creates a new scope with the given query params merged with previous ones" do
        query_scope = relation.query(foo: "Noodles").query({ bar: "Onions" }, { foo: "Meatballs" })
        expect(query_scope).to_not eq(relation)
        expect(query_scope).to be_a(FmRest::Spyke::Relation)
        expect(query_scope.query_params).to eq([{ "foo" => "Noodles", "bar" => "Onions" }])
      end
    end

    context "when there are no key/value collisions" do
      it "creates a new scope with all possible combinations of params" do
        query_scope = relation
          .query({ foo: "Meatballs" }, { foo: "Noodles" })
          .query({ bar: "Onions" }, { bar: "Pickles" })

        expect(query_scope.query_params).to eq [
          { "foo" => "Meatballs", "bar" => "Onions" },
          { "foo" => "Meatballs", "bar" => "Pickles" },
          { "foo" => "Noodles",   "bar" => "Onions" },
          { "foo" => "Noodles",   "bar" => "Pickles" }
        ]
      end
    end

    it "normalizes portal query fields when given a sub-hash" do
      expect(relation.query(ships: { name: "Mary Celeste" }).query_params).to eq([{ "Ships::name" => "Mary Celeste" }])
    end

    it "raises an exception when given a scalar key not matching any attribute" do
      expect { relation.query(no_such_attribute: "very well then") }.to \
        raise_error(FmRest::Spyke::Relation::UnknownQueryKey, /No attribute/)
    end

    it "raises an exception when given a hash key not matching any portal" do
      expect { relation.query(no_such_portal: { a: "A" }) }.to \
        raise_error(FmRest::Spyke::Relation::UnknownQueryKey, /No portal/)
    end

    it "converts Ruby nil to FileMaker empty field condition" do
      expect(relation.query(foo: nil).query_params).to eq([{ "foo" => "=" }])
    end

    it "converts Ruby dates to FileMaker date format" do
      expect(relation.query(foo: Date.civil(2020, 1, 30)).query_params).to eq([{ "foo" => "01/30/2020" }])
    end

    it "converts Ruby datetimes to FileMaker date format" do
      expect(relation.query(foo: DateTime.civil(2020, 1, 30, 0, 0)).query_params).to eq([{ "foo" => "01/30/2020 00:00:00" }])
    end

    it "converts Ruby ranges to FileMaker search ranges" do
      expect(relation.query(foo: (1..5)).query_params).to eq([{ "foo" => "1..5" }])
      expect(relation.query(foo: (1...5)).query_params).to eq([{ "foo" => "1..4" }])
      expect(relation.query(foo: (1.1..5.1)).query_params).to eq([{ "foo" => "1.1..5.1" }])
      expect(relation.query(foo: (1..Float::INFINITY)).query_params).to eq([{ "foo" => ">=1" }])
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.6.0")
        # nil-ended ranges were introduced in Ruby 2.6
        expect(relation.query(foo: (1..nil)).query_params).to eq([{ "foo" => ">=1" }])
      end
      expect(relation.query(foo: (-Float::INFINITY..5)).query_params).to eq([{ "foo" => "<=5" }])
      expect(relation.query(foo: (-Float::INFINITY...5)).query_params).to eq([{ "foo" => "<5" }])
      expect(relation.query(foo: (-Float::INFINITY..Float::INFINITY)).query_params).to eq([{ "foo" => "*" }])
      expect(relation.query(foo: ("A".."Z")).query_params).to eq([{ "foo" => "A..Z" }])
      expect(relation.query(foo: ("A".."Z")).query_params).to eq([{ "foo" => "A..Z" }])
      expect(relation.query(foo: (Date.civil(2020, 1, 30)..Date.civil(2021, 1, 30))).query_params).to eq([{ "foo" => "01/30/2020..01/30/2021" }])
    end

    context "with prefixed .or" do
      it "resets or_flag back to nil" do
        expect(relation.or.query(foo: "Noodles").or_flag).to eq(nil)
      end

      it "adds given params to a separate conditions hash" do
        query_scope = relation.query(foo: "Noodles").or.query({ foo: "Onions" }, { foo: "Meatballs" })
        expect(query_scope.query_params).to eq([{ "foo" => "Noodles" }, { "foo" => "Onions" }, { "foo" => "Meatballs" }])
      end
    end
  end

  describe "#match" do
    it "prefixes the given query values with == and escapes find operators" do
      match_scope = relation.match(foo: "noodle=sp@ghetti", ships: { name: "M@ry" })
      expect(match_scope.query_params).to eq([{
        "foo" => "==noodle\\=sp\\@ghetti",
        "Ships::name" => "==M\\@ry"
      }])
    end
  end

  describe "#omit" do
    it "forwards params to #query with omit: true" do
      expect(relation).to receive(:query).with({ foo: "Coffee", omit: true }).and_return("Yipee!")
      expect(relation.omit(foo: "Coffee")).to eq("Yipee!")
    end
  end

  describe "#or" do
    it "sets or_flag to true" do
      expect(relation.or.or_flag).to eq(true)
    end

    it "forwards params to .query() if any given" do
      query_scope = relation.query(foo: "Noodles").or(foo: "Meatballs")
      expect(query_scope.query_params).to eq([{ "foo" => "Noodles" }, { "foo" => "Meatballs" }])
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

      it "forwards options to fetch" do
        other_relation = FmRest::Spyke::Relation.new(test_class)
        fetch_result, record = double, double
        allow(relation).to receive(:limit).with(1).and_return(other_relation)
        allow(test_class).to receive(:new_collection_from_result).with(fetch_result).and_return([record])
        expect(other_relation).to receive(:fetch).with({ raise_on_no_matching_records: true }).and_return(fetch_result)
        relation.find_one(raise_on_no_matching_records: true)
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
      let(:scope) { relation.limit(10).offset(1).sort(:foo).query(foo: 1).where(__record_id: 1) }

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

    it "is aliased as #first" do
      expect(described_class.instance_method(:first)).to eq(described_class.instance_method(:find_one))
    end

    it "is aliased as #any" do
      expect(described_class.instance_method(:any)).to eq(described_class.instance_method(:find_one))
    end
  end

  describe "#find_one!" do
    it "calls #find_one with raise_on_no_matching_records option" do
      expect(relation).to receive(:find_one).with({ raise_on_no_matching_records: true }).and_return(true)
      relation.find_one!
    end

    it "is aliased as #first" do
      expect(described_class.instance_method(:first!)).to eq(described_class.instance_method(:find_one!))
    end
  end

  describe "#find_in_batches" do
    context "when called with a block" do
      it "calls the block with each batch, not yielding if the last batch is empty" do
        batch_size = 2
        batches = 3 # the last one will be empty
        fetch_calls = 0

        expect(test_class).to receive(:fetch) do
          fetch_calls += 1

          expected_offset = (fetch_calls - 1) * batch_size + 1

          expect(test_class.current_scope.limit_value).to eq(batch_size)
          expect(test_class.current_scope.offset_value).to eq(expected_offset)

          double(
            data: (batches - fetch_calls).zero? ? [] : [{ id: 1 }, { id: 2 }],
            metadata: double(data_info: nil)
          )
        end.exactly(batches).times

        expect { |b| relation.find_in_batches(batch_size: 2, &b) }.to yield_successive_args(
          an_instance_of(Spyke::Collection),
          an_instance_of(Spyke::Collection)
        )
      end

      it "prevents the last request if the found count is a multiple of the batch size" do
        expect(test_class).to receive(:fetch) do
          double(
            data: [{ id: 1 }, { id: 2 }],
            metadata: double(data_info: double(found_count: 2))
          )
        end.once

        expect { |b| relation.find_in_batches(batch_size: 2, &b) }.to yield_control.once
      end
    end

    context "when called without a block" do
      it "returns an Enumerator" do
        expect(relation.find_in_batches).to be_an(Enumerator)
      end

      it "calculates the size of the returned Enumerator through metadata" do
        enum = relation.find_in_batches(batch_size: 10)

        expect(test_class).to receive(:fetch) do
          expect(test_class.current_scope.limit_value).to eq(1)
          double(
            data: [],
            metadata: double(data_info: double(found_count: 90))
          )
        end

        expect(enum.size).to eq(9)
      end
    end
  end

  describe "#find_each" do
    context "when called with a block" do
      it "yields each record independently" do
        allow(relation).to receive(:find_in_batches).and_yield([1, 2]).and_yield([3, 4])

        expect { |b| relation.find_each(&b) }.to yield_successive_args(1, 2, 3, 4)
      end

      it "passes the batch_size option to find_in_batches" do
        expect(relation).to receive(:find_in_batches).with(batch_size: 3)

        relation.find_each(batch_size: 3) {}
      end
    end

    context "when called without a block" do
      it "returns an Enumerator" do
        expect(relation.find_each).to be_an(Enumerator)
      end

      it "calculates the size of the returned Enumerator through metadata" do
        enum = relation.find_each

        expect(test_class).to receive(:fetch) do
          expect(test_class.current_scope.limit_value).to eq(1)
          double(
            data: [],
            metadata: double(data_info: double(found_count: 90))
          )
        end

        expect(enum.size).to eq(90)
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
      expect(scope.sort_params).to eq([{fieldName: "foo"}])
      expect(scope.query_params).to eq([{"foo" => 1}])
    end
  end
end
