# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::V1::RaiseErrors do
  let :faraday do
    Faraday.new("https://stub") do |conn|
      conn.use FmRest::V1::RaiseErrors
      conn.response :json
      conn.adapter Faraday.default_adapter
    end
  end

  context "with message code zero" do
    before do
      stub_request(:post, "https://stub/").to_return_fm
    end

    it "raises no errors" do
      expect { faraday.post("/") }.to_not raise_error
    end
  end

  context "with message code non-zero" do
    let(:error_code) { 10 }

    before do
      stub_request(:post, "https://stub/").to_return_json(
        messages: [{ code: error_code, message: "Some error"}]
      )
    end

    it "raises an APIError" do
      expect { faraday.post("/") }.to raise_error(FmRest::APIError)
    end

    it "includes the error code and message in the exception" do
      begin
        faraday.post("/")
      rescue FmRest::APIError => e
        expect(e.code).to eq(error_code)
        expect(e.message).to eq("FileMaker Data API responded with error #{error_code}: Some error")
      end
    end

    context "with message code -1" do
      let(:error_code) { -1 }

      it "raises an UnknownError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::UnknownError)
      end
    end

    context "with message code between 100-199" do
      let(:error_code) { 100 }

      it "raises a ResourceMissingError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::ResourceMissingError)
      end
    end

    context "with message code 101" do
      let(:error_code) { 101 }

      it "raises a RecordMissingError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::RecordMissingError)
      end
    end

    context "with message code between 200-299" do
      let(:error_code) { 200 }

      it "raises an AccountError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::AccountError)
      end
    end

    context "with message code between 300-399" do
      let(:error_code) { 300 }

      it "raises a LockError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::LockError)
      end
    end

    context "with message code between 400-499" do
      let(:error_code) { 400 }

      it "raises a ParameterError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::ParameterError)
      end
    end

    context "with message code between 500-599" do
      let(:error_code) { 500 }

      it "raises an ValidationError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::ValidationError)
      end
    end

    context "with message code between 800-899" do
      let(:error_code) { 800 }

      it "raises an SystemError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::SystemError)
      end
    end

    context "with message code 952" do
      let(:error_code) { 952 }

      it "raises a InvalidToken" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::InvalidToken)
      end
    end

    context "with message code 953" do
      let(:error_code) { 953 }

      it "raises a MaximumDataAPICallsExceeded" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::MaximumDataAPICallsExceeded)
      end
    end

    context "with message code between 1200-1299" do
      let(:error_code) { 1200 }

      it "raises an ScriptError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::ScriptError)
      end
    end

    context "with message code between 1400-1499" do
      let(:error_code) { 1400 }

      it "raises an ODBCError" do
        expect { faraday.post("/") }.to raise_error(FmRest::APIError::ODBCError)
      end
    end
  end
end
