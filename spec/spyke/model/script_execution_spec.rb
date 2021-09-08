# frozen_string_literal: true

require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::ScriptExecution do
  before { stub_session_login }

  describe ".execute_script" do
    it "runs the script indicated" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/clear_data").to_return_fm
      Ship.execute_script("clear_data")
      expect(request).to have_been_requested
    end

    it "raises error when script is missing" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/bleh").to_return_fm(
        104
      )
      expect { Ship.execute_script("bleh") }.to raise_error(FmRest::APIError::ResourceMissingError)
    end

    it "sends along any passed parameters" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/clear_data?script.param=some%20string").to_return_fm
      Ship.execute_script("clear_data", param: "some string")
      expect(request).to have_been_requested
    end
  end

  describe ".execute" do
    let(:response) do
      { scriptResult: "HELLO", scriptError: "0"}
    end

    it "runs the script indicated" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/clear_data").to_return_fm(response)
      Ship.execute("clear_data")
      expect(request).to have_been_requested
    end

    it "raises error when script is missing" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/bleh").to_return_fm(
        104
      )
      expect { Ship.execute("bleh") }.to raise_error(FmRest::APIError::ResourceMissingError)
    end

    it "sends along any passed parameters as a :param keyword argument" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/clear_data?script.param=some%20string").to_return_fm(response)
      Ship.execute("clear_data", param: "some string")
      expect(request).to have_been_requested
    end

    it "sends along any passed parameters as a single string argument" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/clear_data?script.param=some%20string").to_return_fm(response)
      Ship.execute("clear_data", "some string")
      expect(request).to have_been_requested
    end

    it "it returns just the script results object" do
      request = stub_request(:get, fm_url(layout: "Ships") + "/script/clear_data?script.param=some%20string").to_return_fm(response)
      result = Ship.execute("clear_data", "some string")
      expect(result.result).to eq("HELLO")
      expect(result.error).to eq("0")
    end
  end
end
