require "support/webmock"

module RequestStubs
  def fm_url(host: FMDATA_DUMMY_CONFIG[:host], database: FMDATA_DUMMY_CONFIG[:database], layout: nil, id: nil)
    "https://#{host}/fmi/data/v1/databases/#{database}".tap do |url|
      if layout
        url << "/layouts/#{layout}"
        url << "/records/#{id}" if id
      end
    end
  end

  def stub_session_login(host: FMDATA_DUMMY_CONFIG[:host], database: FMDATA_DUMMY_CONFIG[:database], token: "MOCK_SESSION_TOKEN")
    stub_request(:post, fm_url(host: host, database: database) + "/sessions").to_return_fm(token: token)
  end
end

RSpec.configure do |config|
  config.include RequestStubs
end
