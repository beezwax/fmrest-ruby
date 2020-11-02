require "spec_helper"

# Custom matcher module for comparing Metadata objects
#
# See examples in specs below for usage
#
module MetadataMatchers
  extend RSpec::Matchers::DSL

  matcher :a_metadata_object do |expected|
    match do |actual|
      matches = actual.kind_of?(FmRest::Spyke::Metadata)

      if @messages
        matches &&=
          @messages.all? do |expecm|
            actual.messages.any? do |m|
              expecm[:code] === m.code && expecm[:message] === m.message
            end
          end
      end

      if @script_results
        matches &&=
          @script_results.all? { |k, v| v === actual.script[k].to_h }
      end

      if @data_info
        matches &&= (@data_info === actual.data_info.to_h)
      end

      matches
    end

    chain :with_messages do |*messages|
      @messages = messages
    end

    chain :with_ok_message do
      @messages = [{ code: "0", message: "OK" }]
    end

    chain :with_script_results do |results|
      @script_results = results
    end

    chain :with_data_info do |data_info|
      @data_info = data_info
    end
  end
end

RSpec.describe FmRest::Spyke::Metadata do
  it "aliases script as scripts" do
    expect(described_class.instance_method(:scripts)).to eq(described_class.instance_method(:script))
  end
end

RSpec.describe FmRest::Spyke::DataInfo do
  let(:instance) { described_class.new(totalRecordCount: 10, foundCount: 5, returnedCount: 2) }

  it "aliases totalRecordCount as total_record_count" do
    expect(instance.total_record_count).to eq(10)
  end

  it "aliases foundCount as found_count" do
    expect(instance.found_count).to eq(5)
  end

  it "aliases returnedCount as returned_count" do
    expect(instance.returned_count).to eq(2)
  end
end


RSpec.describe FmRest::Spyke::SpykeFormatter do
  include MetadataMatchers

  let :model do
    fmrest_spyke_class do
      has_portal :portal1, attribute_prefix: "PortalOne"
    end
  end

  let :data_info do
    {
      database: "Database",
      layout: "Layout",
      table: "Table",
      totalRecordCount: 100,
      foundCount: 50,
      returnedCount: 20
    }
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

        dataInfo: data_info
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
        metadata: a_metadata_object.with_ok_message,
        data: {
          __record_id: 1,
          __mod_id: "1",
          foo: "Foo",
          portal1: [{ bar: "Bar", __record_id: 1, __mod_id: "1" }]
        }
      )
    end
  end

  context "when requesting a collection through the collection URL" do
    it "returns a hash with collection data" do
      response = faraday.post('/_find')

      expect(response.body).to include(
        metadata: a_metadata_object
          .with_ok_message
          .with_data_info(data_info),
        data: [{
          __record_id: 1,
          __mod_id: "1",
          foo: "Foo",
          portal1: [{ bar: "Bar", __record_id: 1, __mod_id: "1" }]
        }]
      )
    end
  end

  context "when requesting a collection through the find API" do
    it "returns a hash with collection data" do
      response = faraday.post('/_find')

      expect(response.body).to include(
        metadata: a_metadata_object
          .with_ok_message
          .with_data_info(data_info),
        data: [{
          __record_id: 1,
          __mod_id: "1",
          foo: "Foo",
          portal1: [{ bar: "Bar", __record_id: 1, __mod_id: "1" }]
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
            metadata: a_metadata_object.with_ok_message,
            data: { __mod_id: "2" },
            errors: {}
          )
        end
      end

      context "when unsucessful" do
        let :response_json do
          {
            response: {},
            messages: [
              { code: "555", message: "Very angry validation error" },
              { code: "800", message: "Chill non-validation error" }
            ]
          }
        end

        it "returns a hash with validation errors" do
          expect(response.body).to include(
            metadata: a_metadata_object.with_messages(
              { code: "800", message: "Chill non-validation error" },
              { code: "555", message: "Very angry validation error" }
            ),
            data: {},
            errors: {
              base: [ "Very angry validation error (555)" ]
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
          metadata: a_metadata_object.with_ok_message,
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
          metadata: a_metadata_object
            .with_ok_message
            .with_script_results(
              after: { error: "0", result: "hello" },
              presort: { error: "0", result: "hello presort" },
              prerequest: { error: "0", result: "hello prerequest" }
            ),
          errors: {}
        )
      end
    end
  end
end
