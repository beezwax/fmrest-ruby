# frozen_string_literal: true

require "support/webmock"
require "uri"

module RequestStubs
  def fm_url(host: FMREST_DUMMY_CONFIG[:host], database: FMREST_DUMMY_CONFIG[:database], layout: nil, id: nil)
    String.new("https://#{host}/fmi/data/v1/databases/#{FmRest::V1.url_encode(database)}").tap do |url|
      if layout
        url << "/layouts/#{URI.encode_www_form_component(layout)}"
        url << "/records/#{id}" if id
      end

      url.freeze
    end
  end

  def stub_session_login(host: FMREST_DUMMY_CONFIG[:host], database: FMREST_DUMMY_CONFIG[:database], token: "MOCK_SESSION_TOKEN")
    stub_request(:post, fm_url(host: host, database: database) + "/sessions").to_return_fm(token: token)
  end
end

RSpec.configure do |config|
  config.include RequestStubs
end
