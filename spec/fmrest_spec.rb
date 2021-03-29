RSpec.describe FmRest do
  it "has a version number" do
    expect(FmRest::VERSION).not_to be nil
  end

  describe ".token_store" do
    xit "sets the token store"
  end

  describe ".default_connection_settings" do
    xit "sets the default connection settings"
  end

  describe ".e" do
    it "behaves as an alias of FmRest::V1.escape_find_operators" do
      expect(FmRest::V1).to receive(:escape_find_operators).with("foo").and_return("bar")
      expect(FmRest.e("foo")).to eq("bar")
    end
  end
end
