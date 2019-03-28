require "spec_helper"

RSpec.describe FmRest::Spyke::JsonParser do
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
              recordId: 1,
              modId: 1
            }]
          },

          modId: 1,
          recordId: 1
        }],
      },
      messages: [{ code: "0", message: "OK" }]
    }
  end

  let :faraday do
    Faraday.new do |conn|
      conn.use described_class, model

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
      end
    end
  end

  context "when requesting a single record by id" do
    it "returns a hash with single record data" do
      response = faraday.get('/records/1')

      expect(response.body).to include(
        metadata: {
          messages: [{code: "0", message: "OK"}]
        },
        data: {
          id: 1,
          mod_id: 1,
          foo: "Foo",
          portal1: [{ bar: "Bar", id: 1, mod_id: 1 }]
        }
      )
    end
  end

  context "when requesting a collection through the collection URL" do
    it "returns a hash with collection data" do
      response = faraday.post('/_find')

      expect(response.body).to include(
        metadata: {
          messages: [{code: "0", message: "OK"}]
        },
        data: [{
          id: 1,
          mod_id: 1,
          foo: "Foo",
          portal1: [{ bar: "Bar", id: 1, mod_id: 1 }]
        }]
      )
    end
  end

  context "when requesting a collection through the find API" do
    it "returns a hash with collection data" do
      response = faraday.post('/_find')

      expect(response.body).to include(
        metadata: {
          messages: [{code: "0", message: "OK"}]
        },
        data: [{
          id: 1,
          mod_id: 1,
          foo: "Foo",
          portal1: [{ bar: "Bar", id: 1, mod_id: 1 }]
        }]
      )
    end
  end

  [["updating", :patch, "/records/1"], ["creating", :post, '/records']].each do |(action, method, endpoint)|
    context "when #{action} a record" do
      let(:response) { faraday.send(method, endpoint) }

      context "when sucessful" do
        let :response_json do
          {
            response: { modId: 2 },
            messages: [{code: "0", message: "OK"}]
          }
        end

        it "returns a hash with single record data" do
          expect(response.body).to include(
            metadata: {
              messages: [{code: "0", message: "OK"}]
            },
            data: { mod_id: 2 },
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
              ]
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
            messages: [{code: "0", message: "OK"}]
          },
          data: {},
          errors: {}
        )
      end
    end
  end
end
