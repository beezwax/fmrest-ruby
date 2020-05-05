require "spec_helper"

require "fixtures/pirates"

RSpec.describe FmRest::Spyke::Model::Auth do
  after(:all) do
    Ship.instance_variable_set(:@fmrest_connection, nil)
  end

  describe ".logout!" do
    context "with a token set" do
      let(:token) { "TOKEN" }

      before do
        stub_session_login(token: token)
        stub_request(:get, fm_url + "/").to_return_fm
        Ship.connection.get
      end

      it "sends a DELETE request to the session path" do
        logout_request = stub_request(:delete, fm_url + "/sessions/#{token}").to_return_fm

        Ship.logout!

        expect(logout_request).to have_been_requested
      end
    end

    context "with no token set" do
      it "raises an exception" do
        expect { Ship.logout! }.to raise_error(FmRest::V1::TokenSession::NoSessionTokenSet)
      end
    end
  end

  describe ".logout" do
    context "with a token set" do
      let(:token) { "TOKEN" }

      before do
        stub_session_login(token: token)
        stub_request(:get, fm_url + "/").to_return_fm
        Ship.connection.get

        @logout_request = stub_request(:delete, fm_url + "/sessions/#{token}").to_return_fm
      end

      it "sends a DELETE request to the session path" do
        Ship.logout
        expect(@logout_request).to have_been_requested
      end

      it "returns true" do
        expect(Ship.logout).to eq(true)
      end
    end

    context "with no token set" do
      it "returns false" do
        expect(Ship.logout).to eq(false)
      end
    end
  end
end
