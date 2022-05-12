# frozen_string_literal: true

RSpec.describe FmRest::Spyke::ContainerField do
  let(:url) { "https://foo" }

  let(:faraday) { double(Faraday) }
  let(:model_class) { double("ModelClass", layout: "MyLayout", connection: faraday) }

  let(:record) do
    double(FmRest::Spyke::Base, attributes: { "container" => url },
                                __record_id: 1,
                                persisted?: true,
                                class: model_class)
  end

  let(:container) { FmRest::Spyke::ContainerField.new(record, "container") }

  describe "#initialize" do
    it "sets base and name" do
      expect(container.instance_variable_get(:@base)).to eq(record)
      expect(container.name).to eq("container")
    end
  end

  describe "#name" do
    it "returns the name" do
      expect(container.name).to eq("container")
    end
  end

  describe "#url" do
    it "returns the url for the container field" do
      expect(container.url).to eq(url)
    end
  end

  describe "#download" do
    let(:io) { double(IO) }

    it "returns an IO object with the contained file" do
      expect(FmRest::V1).to receive(:fetch_container_data).with(url, faraday).and_return(io)
      expect(container.download).to eq(io)
    end
  end

  describe "#upload" do
    let(:io) { double(IO) }

    before do
      allow(FmRest::V1).to receive(:upload_container_data).and_return(double("Response", body: { data: { __mod_id: 99 } }))
      allow(record).to receive(:__mod_id=)
    end

    context "with an unpersisted record" do
      let(:record) { double(FmRest::Spyke::Base, persisted?: false) }

      it "raises error" do
        expect { container.upload(io) }.to raise_error(ArgumentError)
      end
    end

    it "accepts :repetition option" do
      expect(FmRest::V1).to receive(:container_field_path).with(anything, anything, anything, 33)
      container.upload(io, repetition: 33)
    end

    it "updates mod_id" do
      expect(record).to receive(:__mod_id=).with(99)
      container.upload(io)
    end

    it "returns true when successful" do
      allow(record).to receive(:__mod_id=)
      expect(container.upload(io)).to eq(true)
    end
  end
end
