require "spec_helper"

RSpec.describe FmRest::V1::ContainerFields do
  let(:extendee) { Object.new.tap { |obj| obj.extend(described_class) } }

  describe "#fetch_container_data" do
    let(:container_url) { "https://foo.bar/qux" }

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

    context "when the given URL is not a redirect" do
      it "returns an IO object with the container field contents" do
        stub_request(:get, container_url).to_return(body: "hi there")

        expect(extendee.fetch_container_data(container_url).read).to eq("hi there")
      end
    end

    context "when the given URL is a redirect" do
      context "but doesn't return a Set-Cookie header" do
        it "raises an FmRest::ContainerFieldError" do
          stub_request(:get, container_url).to_return(status: 302, headers: { "Location" => container_url })

          expect { extendee.fetch_container_data(container_url) }.to raise_error(FmRest::ContainerFieldError, /session cookie/)
        end
      end

      context "and returns a Set-Cookie header" do
        it "returns an IO object with the container field contents" do
          stub_request(:get, container_url).to_return(status: 302, headers: { "Location" => container_url, "Set-Cookie" => "secret cookie" })
          stub_request(:get, container_url).with(headers: { "Cookie" => "secret cookie" }).to_return(body: "hi there")

          expect(extendee.fetch_container_data(container_url).read).to eq("hi there")
        end
      end
    end 

    context "when given a base Faraday connection" do
      # NOTE: These specs are too close to implementation, but there doesn't
      # seem to be another way around it since WebMock can't mock SSL/proxy
      # requests, which would be the ideal way of testing this

      let(:faraday_options) { { ssl: { verify: false, cert_store: __dir__ }, proxy: "http://proxy.foo.bar" } }

      let!(:base_faraday) { Faraday.new(nil, faraday_options) }

      before do
        stub_request(:get, container_url).to_return(body: "hi there")
      end

      after :each do
        extendee.fetch_container_data(container_url, base_faraday)
      end

      it "uses a new Faraday connection with copied SSL and proxy options" do
        faraday = Faraday.new(nil, faraday_options)

        expect(Faraday).to receive(:new)
          .with(anything, ssl: { verify: false, cert_store: __dir__ }, proxy: { uri: URI.parse("http://proxy.foo.bar") })
          .and_return(faraday)
      end

      it "calls URI#open with right SSL and proxy options" do
        expect_any_instance_of(URI::HTTPS).to receive(:open)
          .with(hash_including(
            ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
            ssl_ca_cert:     __dir__,
            proxy:           URI("http://proxy.foo.bar")
          ))
      end

      context "with authenticated proxy option" do
        let(:faraday_options) { { proxy: "http://user:pass@proxy.foo.bar" } }

        it "calls URI#open with right SSL and proxy options" do
          expect_any_instance_of(URI::HTTPS).to receive(:open)
            .with(hash_including(
              proxy_http_basic_authentication: [URI("http://proxy.foo.bar"), "user", "pass"]
            ))
        end
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
