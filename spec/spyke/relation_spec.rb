RSpec.describe FmData::Spyke::Relation do
  let(:test_class) do
    fmdata_spyke_class do
      attributes :foo, :bar
    end
  end

  let(:relation) { FmData::Spyke::Relation.new(test_class) }

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
      expect(limit_scope).to be_a(FmData::Spyke::Relation)
      expect(limit_scope.limit_value).to eq(1010)
    end
  end

  describe "#offset" do
    it "creates a new scope with the given offset" do
      offset_scope = relation.offset(22)
      expect(offset_scope).to_not eq(relation)
      expect(offset_scope).to be_a(FmData::Spyke::Relation)
      expect(offset_scope.offset_value).to eq(22)
    end
  end

  describe "#sort" do
    it "creates a new scope with the given sort params" do
      sort_scope = relation.sort(:foo, :bar!)
      expect(sort_scope).to_not eq(relation)
      expect(sort_scope).to be_a(FmData::Spyke::Relation)
      expect(sort_scope.sort_params).to eq([{ fieldName: :foo }, { fieldName: :bar, sortOrder: "descend" }])
    end
  end

  describe "#order" do
    it "is an alias for #sort" do
      expect(FmData::Spyke::Relation.instance_method(:order)).to eq(FmData::Spyke::Relation.instance_method(:sort))
    end
  end

  describe "#portal" do
    xit "creates a new scope with the given portal params"
    xit "accepts a list of arguments, a single string or an array"
  end

  describe "#includes" do
    it "is an alias for #portal" do
      expect(FmData::Spyke::Relation.instance_method(:includes)).to eq(FmData::Spyke::Relation.instance_method(:portal))
    end
  end

  describe "#query" do
    it "creates a new scope with the given query params merged with previous ones" do
      query_scope = relation.query(foo: "Noodles").query(bar: "Onions", omit: true)
      expect(query_scope).to_not eq(relation)
      expect(query_scope).to be_a(FmData::Spyke::Relation)
      expect(query_scope.query_params).to eq([{ "foo" => "Noodles" }, { "bar" => "Onions", "omit" => "true" }])
    end
  end

  describe "#omit" do
    it "forwards params to #query with omit: true" do
      expect(relation).to receive(:query).with(foo: "Coffee", omit: true).and_return("Yipee")
      expect(relation.omit(foo: "Coffee")).to eq("Yipee")
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
end
