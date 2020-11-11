# frozen_string_literal: true

require "spec_helper"
require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::Http do
  describe ".request" do
    let(:ship) { Ship.new __record_id: 1, name: "Obra Djinn" }

    before { stub_session_login }

    it "sets the last_request_metadata for the current thread" do
      stub_request(:get, fm_url + "/").to_return_fm(
        scriptResult: "hello",
        scriptError: "0"
      )

      expect { Ship.request(:get, "") }.to change(Ship, :last_request_metadata)
    end
  end

  describe ".last_request_metadata" do
    it "reads the class-and-thread-local metadata variable" do
      t1 = Thread.new do
        Thread.current["__a"] = 1
        expect(Ship.last_request_metadata(key: "__a")).to eq(1)
      end

      t2 = Thread.new do
        Thread.current["__a"] = 2
        expect(Ship.last_request_metadata(key: "__a")).to eq(2)
      end

      t1.join
      t2.join
    end
  end

  # NOTE: .find is a core Spyke method which we don't override, but we're
  # testing here anyway since the changes to #uri bellow affect it
  describe ".find" do
    before { stub_session_login }

    it "sends the proper request" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/records/1").to_return_fm(
        data: [{ recordId: "1", fieldData: {} }]
      )
      Ship.find(1)
      expect(request).to have_been_requested
    end
  end

  describe "#uri" do
    context "when the record is persisted" do
      it "returns a Spyke::Path object with the record_id set in params" do
        uri = Ship.new(__record_id: 1, name: "Obra Djinn" ).uri
        expect(uri).to be_a(::Spyke::Path)
        # This is ugly but Spyke::Path provides no public reader for params
        expect(uri.instance_variable_get(:@params)).to match(__record_id: 1)
      end
    end

    context "when the record is not persisted" do
      it "returns a Spyke::Path object with no record_id set in params" do
        uri = Ship.new(name: "Obra Djinn").uri
        expect(uri).to be_a(::Spyke::Path)
        expect(uri.instance_variable_get(:@params)).to eq({})
      end
    end

    context "when called within a scoped record" do
      it "returns a Spyke::Path object with the record_id set in params" do
        uri = Ship.where(__record_id: 1).new.uri
        expect(uri).to be_a(::Spyke::Path)
        expect(uri.instance_variable_get(:@params)).to match(__record_id: 1)
      end
    end
  end
end
