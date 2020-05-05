require "support/webmock"
require "uri"

module RequestStubs
  def fm_url(host: FMREST_DUMMY_CONFIG[:host], database: FMREST_DUMMY_CONFIG[:database], layout: nil, id: nil)
    "https://#{host}/fmi/data/v1/databases/#{URI.escape(database)}".tap do |url|
      if layout
        url << "/layouts/#{URI.escape(layout)}"
        url << "/records/#{id}" if id
      end
    end
  end

  def stub_session_login(host: FMREST_DUMMY_CONFIG[:host], database: FMREST_DUMMY_CONFIG[:database], token: "MOCK_SESSION_TOKEN")
    stub_request(:post, fm_url(host: host, database: database) + "/sessions").to_return_fm(token: token)
  end
end

RSpec.configure do |config|
  config.include RequestStubs
end
