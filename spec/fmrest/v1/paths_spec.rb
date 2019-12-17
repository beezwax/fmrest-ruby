require "spec_helper"

RSpec.describe FmRest::V1::Paths do
  let(:extendee) { Object.new.tap { |obj| obj.extend(described_class) } }

  describe "#session_path" do
    it "returns just `sessions' when called without a token" do
      expect(extendee.session_path).to eq("sessions")
    end

    it "returns sessions/:token when called with a token" do
      expect(extendee.session_path("+TOKEN+")).to eq("sessions/+TOKEN+")
    end
  end

  describe "#record_path" do
    it "returns layouts/:layout/records when called without an id" do
      expect(extendee.record_path("Some Layout")).to eq("layouts/Some%20Layout/records")
    end

    it "returns layouts/:layout/records/:id when called with an id" do
      expect(extendee.record_path("Some Layout", 1337)).to eq("layouts/Some%20Layout/records/1337")
    end

    it "encodes the path correctly when a layout contains brackets and spaces" do
      expect(extendee.record_path("Some Layout [horribleUrL]")).to eq("layouts/Some%20Layout%20%5BhorribleUrL%5D/records")
    end
  end

  describe "#container_field_path" do
    it "returns layouts/:layout/records/:id/containers/:field_name/1 when called without field_repetition" do
      expect(extendee.container_field_path("Some Layout", 66, "My Container Field")).to eq("layouts/Some%20Layout/records/66/containers/My%20Container%20Field/1")
    end

    it "returns layouts/:layout/records/:id/containers/:field_name/:field_repetition when called with field_repetition" do
      expect(extendee.container_field_path("Some Layout", 66, "My Container Field", 10)).to eq("layouts/Some%20Layout/records/66/containers/My%20Container%20Field/10")
    end

    it "encodes the path correctly when a field name contains brackets and spaces" do
      expect(extendee.container_field_path("Some [Horrible] Layout", 77, "[Ugly] Field")).to eq("layouts/Some%20%5BHorrible%5D%20Layout/records/77/containers/%5BUgly%5D%20Field/1")
    end
  end

  describe "#find_path" do
    it "returns layouts/:layout/_find" do
      expect(extendee.find_path("Some Layout")).to eq("layouts/Some%20Layout/_find")
    end
  end

  describe "#script_path" do
    it "returns layouts/:layout/scripts/:script" do
      expect(extendee.script_path("Some Layout", "Some script")).to eq("layouts/Some%20Layout/script/Some%20script")
    end
  end

  describe "#globals_path" do
    it "returns globals" do
      expect(extendee.globals_path).to eq("globals")
    end
  end
end
