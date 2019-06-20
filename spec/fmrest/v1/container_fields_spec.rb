require "spec_helper"

RSpec.describe FmRest::V1::ContainerFields do
  let(:extendee) { Object.new.tap { |obj| obj.extend(described_class) } }

  describe "#fetch_container_data" do
    context "when given an invalid URL" do
      it "raises an FmRest::ContainerFieldError" do
        expect { extendee.fetch_container_data("boo boo") }.to raise_error(FmRest::ContainerFieldError, /Invalid container field URL/)
      end
    end

    context "when given a non-http URL" do
      it "raises an FmRest::ContainerFieldError" do
        expect { extendee.fetch_container_data("file://foo/bar") }.to raise_error(FmRest::ContainerFieldError, /Container URL is not HTTP/)
      end
    end

    context "when the given URL doesn't return a Set-Cookie header" do
      let(:container_url) { "http://foo.bar/qux" }

      before do
        stub_request(:get, container_url).to_return(body: "foo")
      end

      it "raises an FmRest::ContainerFieldError" do
        expect { extendee.fetch_container_data(container_url) }.to raise_error(FmRest::ContainerFieldError, /session cookie/)
      end
    end

    context "when the given URL returns a Set-Cookie header" do
      let(:container_url) { "http://foo.bar/qux" }

      before do
        stub_request(:get, container_url).to_return(headers: { "Set-Cookie" => "secret cookie" })
        stub_request(:get, container_url).with(headers: { "Cookie" => "secret cookie" }).to_return(body: "hi there")
      end

      it "returns an IO object with the container field contents" do
        expect(extendee.fetch_container_data(container_url).read).to eq("hi there")
      end
    end
  end

  describe "#upload_container_data" do
    before { stub_session_login }

    let(:connection) { FmRest::V1.build_connection(FMREST_DUMMY_CONFIG) }
    let(:container_path) { "layouts/MyLayout/records/1/container/path" }

    let(:content) { "hello" }
    let(:io) { StringIO.new(content) }
    let(:filename) { "local.path" }
    let(:content_type) { "application/octet-stream" }
    let(:boundary) { /-----------RubyMultipartPost-[a-f0-9]{32}/ }

    let(:expected_headers) { { "Content-Type" => %r{\Amultipart/form-data; boundary=#{boundary}\Z} } }
    let(:expected_body) do
      # Multipart block headers
      content_disposition_matcher = /Content-Disposition: form-data; name="upload"; filename="#{filename}"/
      content_length_matcher = /Content-Length: #{content.length}/
      content_type_matcher = /Content-Type: #{content_type}/
      content_transfer_encoding_matcher = /Content-Transfer-Encoding: binary/

      # Full multipart body
      /\A--#{boundary}\W+#{content_disposition_matcher}\W+#{content_length_matcher}\W+#{content_type_matcher}\W+#{content_transfer_encoding_matcher}\W+#{content}\W+--#{boundary}--\W+\z/
    end

    before do
      stub_request(:post, fm_url(layout: "MyLayout", id: 1) + "/container/path")
        .with(headers: expected_headers) { |request| request.body =~ expected_body }
        .to_return_fm(mod_id: 1)
    end

    it "uploads" do
      response = extendee.upload_container_data(connection, container_path, io)
      expect(response.body["response"]["mod_id"]).to eq(1)
    end

    context "with :filename option given" do
      let(:filename) { "my_fancy_filename.txt" }

      it "uploads with proper filename set in Content-Disposition" do
        response = extendee.upload_container_data(connection, container_path, io, filename: "my_fancy_filename.txt")
        expect(response.body["response"]["mod_id"]).to eq(1)
      end
    end

    context "with :content_type option given" do
      let(:content_type) { "application/dust" }

      it "uploads with proper filename set in Content-Disposition" do
        response = extendee.upload_container_data(connection, container_path, io, content_type: "application/dust")
        expect(response.body["response"]["mod_id"]).to eq(1)
      end
    end

    context "with an IO that has responds to original_filename" do
      let(:filename) { "my_fancy_filename.txt" }

      it "uploads with proper filename set in Content-Disposition" do
        allow(io).to receive(:original_filename).and_return(filename)
        response = extendee.upload_container_data(connection, container_path, io)
        expect(response.body["response"]["mod_id"]).to eq(1)
      end
    end

    context "with a file path given as a string" do
      let(:io) { File.join(__dir__, "../../support/data/upload_test.txt") }
      let(:filename) { "upload_test.txt" }
      let(:content) { "hello\n" }

      it "uploads the contents of the file, setting its filename" do
        response = extendee.upload_container_data(connection, container_path, io)
        expect(response.body["response"]["mod_id"]).to eq(1)
      end
    end
  end
end
