require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::Http do
  describe ".request" do
    let(:ship) { Ship.new id: 1, name: "Obra Djinn" }

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
end
