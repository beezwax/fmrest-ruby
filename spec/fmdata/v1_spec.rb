RSpec.describe FmData::V1 do
  describe ".build_connection" do
    xit "works"
  end

  describe ".base_connection" do
    xit "works"
  end

  describe ".session_path" do
    it "returns just `sessions' when called without a token" do
      expect(FmData::V1.session_path).to eq("sessions")
    end

    it "returns sessions/:token when called with a token" do
      expect(FmData::V1.session_path("+TOKEN+")).to eq("sessions/+TOKEN+")
    end
  end

  describe ".record_path" do
    it "returns layouts/:layout/records when called without an id" do
      expect(FmData::V1.record_path("Some Layout")).to eq("layouts/Some%20Layout/records")
    end

    it "returns layouts/:layout/records/:id when called with an id" do
      expect(FmData::V1.record_path("Some Layout", 1337)).to eq("layouts/Some%20Layout/records/1337")
    end
  end

  describe ".find_path" do
    it "returns layouts/:layout/_find" do
      expect(FmData::V1.find_path("Some Layout")).to eq("layouts/Some%20Layout/_find")
    end
  end
end
