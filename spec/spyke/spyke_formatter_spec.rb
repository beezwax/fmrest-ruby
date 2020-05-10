require "spec_helper"

RSpec.describe FmRest::Spyke::SpykeFormatter do
  let :model do
    fmrest_spyke_class do
      has_portal :portal1, attribute_prefix: "PortalOne"
    end
  end

  let :response_json do
    {
      response: {
        data: [{
          fieldData: {
            foo: "Foo"
          },

          portalData: {
            portal1: [{
              "PortalOne::bar": "Bar",
              recordId: "1",
              modId: "1"
            }]
          },

          modId: "1",
          recordId: "1"
        }],
      },
      messages: [{ code: "0", message: "OK" }]
    }
  end

  let :faraday do
    Faraday.new do |conn|
      conn.use described_class, model
      conn.response :json, parser_options: { symbolize_names: true }

      conn.adapter :test do |stub|
        stub.get '/records/1' do
          [200, {}, response_json.to_json]
        end

        stub.post '/_find' do
          [200, {}, response_json.to_json]
        end

        stub.post '/records' do
          [200, {}, response_json.to_json]
        end

        stub.patch '/records/1' do
          [200, {}, response_json.to_json]
        end

        stub.delete '/records/1' do
          [200, {}, response_json.to_json]
        end

        stub.post '/records/1/containers/Pie/1' do
          [200, {}, response_json.to_json]
        end

        stub.get '/script/DoSomethingUseful' do
          [200, {}, response_json.to_json]
        end
      end
    end
  end

  context "when requesting a single record by id" do
    it "returns a hash with single record data" do
      response = faraday.get('/records/1')

      expect(response.body).to include(
        metadata: {
          messages: [{code: "0", message: "OK"}],
          script: nil
        },
        data: {
          id: 1,
          mod_id: "1",
          foo: "Foo",
          portal1: [{ bar: "Bar", id: 1, mod_id: "1" }]
        }
      )
    end
  end

  context "when requesting a collection through the collection URL" do
    it "returns a hash with collection data" do
      response = faraday.post('/_find')

      expect(response.body).to include(
        metadata: {
          messages: [{code: "0", message: "OK"}],
          script: nil
        },
        data: [{
          id: 1,
          mod_id: "1",
          foo: "Foo",
          portal1: [{ bar: "Bar", id: 1, mod_id: "1" }]
        }]
      )
    end
  end

  context "when requesting a collection through the find API" do
    it "returns a hash with collection data" do
      response = faraday.post('/_find')

      expect(response.body).to include(
        metadata: {
          messages: [{code: "0", message: "OK"}],
          script: nil
        },
        data: [{
          id: 1,
          mod_id: "1",
          foo: "Foo",
          portal1: [{ bar: "Bar", id: 1, mod_id: "1" }]
        }]
      )
    end
  end

  [["updating a record", :patch, "/records/1"], ["creating a record", :post, "/records"], ["uploading to a container", :post, "/records/1/containers/Pie/1"]].each do |(action, method, endpoint)|
    context "when #{action}" do
      let(:response) { faraday.send(method, endpoint) }

      context "when sucessful" do
        let :response_json do
          {
            response: { modId: "2" },
            messages: [{code: "0", message: "OK"}]
          }
        end

        it "returns a hash with single record data" do
          expect(response.body).to include(
            metadata: {
              messages: [{code: "0", message: "OK"}],
              script: nil
            },
            data: { mod_id: "2" },
            errors: {}
          )
        end
      end

      context "when unsucessful" do
        let :response_json do
          {
            response: {},
            messages: [
              {code: "555", message: "Very angry validation error"},
              {code: "800", message: "Chill non-validation error"}
            ]
          }
        end

        it "returns a hash with validation errors" do
          expect(response.body).to include(
            metadata: {
              messages: [
                {code: "555", message: "Very angry validation error"},
                {code: "800", message: "Chill non-validation error"}
              ],
              script: nil
            },
            data: {},
            errors: {
              base: [
                "Very angry validation error (555)"
              ]
            }
          )
        end
      end
    end
  end

  context "when deleting a record" do
    context "when sucessful" do
      let :response_json do
        {
          response: {},
          messages: [{code: "0", message: "OK"}]
        }
      end

      it "returns a hash with single record data" do
        response = faraday.delete('/records/1')

        expect(response.body).to include(
          metadata: {
            messages: [{code: "0", message: "OK"}],
            script: nil
          },
          data: {},
          errors: {}
        )
      end
    end
  end

  context "when executing a script" do
    context "when sucessful" do
      let :response_json do
        {
          response: {
            scriptError: "0",
            scriptResult: "hello",

            "scriptError.prerequest": "0",
            "scriptResult.prerequest": "hello prerequest",

            "scriptError.presort": "0",
            "scriptResult.presort": "hello presort"
          },
          messages: [{code: "0", message: "OK"}]
        }
      end

      it "returns a hash with just script execution results" do
        response = faraday.get('/script/DoSomethingUseful?script.param=5')

        expect(response.body).to include(
          metadata: {
            messages: [{code: "0", message: "OK"}],
            script: {
              after: { error: "0", result: "hello" },
              presort: { error: "0", result: "hello presort" },
              prerequest: { error: "0", result: "hello prerequest" }
            }
          },
          errors: {}
        )
      end
    end
  end
end
