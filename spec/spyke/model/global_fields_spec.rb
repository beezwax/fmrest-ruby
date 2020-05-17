require "spec_helper"

RSpec.describe FmRest::Spyke::Model::GlobalFields do
  let :test_class { fmrest_spyke_class }

  describe ".set_globals" do
    before { stub_session_login }

    let(:request) { stub_request(:patch, fm_url + "/globals").to_return_fm }

    context "when given a valid values hash" do
      it "builds and sends the correct JSON PATCH request" do
        request.with(body: {
          globalFields: {
            "foo::x" => "a",
            "bar::y" => "b",
            "bar::z" => "c"
          }
        })
        test_class.set_globals("foo::x" => "a", bar: { y: "b", z: "c" })
        expect(request).to have_been_requested
      end
    end

    context "when given a values hash with invalid keys" do
      it "raises an ArgumentError" do
        expect { test_class.set_globals(foo: "bar") }.to raise_error(ArgumentError, /fully qualified/)
      end
    end
  end
end
