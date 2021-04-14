RSpec.describe FmRest do
  it "has a version number" do
    expect(FmRest::VERSION).to be_a(String)
  end

  describe "token_store accessor" do
    it do
      orig_store = FmRest.token_store
      expect { FmRest.token_store = :dummy_store }.to change { FmRest.token_store }.to :dummy_store
      FmRest.token_store = orig_store
    end
  end

  describe "default_connection_settings accessor" do
    it "sets settings as an FmRest::ConnectionSettings instance" do
      orig_settings = FmRest.default_connection_settings

      FmRest.default_connection_settings = { username: "Alice", password: "correct horse" }

      expect(FmRest.default_connection_settings).to be_a(FmRest::ConnectionSettings)
      expect(FmRest.default_connection_settings[:username]).to eq("Alice")
      expect(FmRest.default_connection_settings[:password]).to eq("correct horse")

      FmRest.default_connection_settings = orig_settings
    end
  end

  describe ".logger" do
    it "defaults to Rails' logger if available" do
      Object::Rails = double(:Rails, logger: :rails_logger)
      expect(FmRest.logger).to eq(:rails_logger)
      Object.send(:remove_const, :Rails)
      FmRest.logger = nil # reset memoized value
    end

    it "defaults to a new Logger instance Rails is not available" do
      expect(FmRest.logger).to be_a(Logger)
    end
  end

  describe ".logger=" do
    it "sets the logger" do
      expect { FmRest.logger = :new_logger }.to change { FmRest.logger }.to(:new_logger)
    end
  end

  describe ".e" do
    it "behaves as an alias of FmRest::V1.escape_find_operators" do
      expect(FmRest::V1).to receive(:escape_find_operators).with("foo").and_return("bar")
      expect(FmRest.e("foo")).to eq("bar")
    end
  end
end
