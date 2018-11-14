require "support/webmock"

module RequestStubs
  def fm_url(host: "example.com", database: "TestDB", layout: nil, id: nil)
    "https://#{host}/fmi/data/v1/databases/#{database}".tap do |url|
      if layout
        url << "/layouts/#{layout}"
        url << "/records/#{id}" if id
      end
    end
  end

  def stub_session_login(host: "example.com", database: "TestDB", token: "MOCK_SESSION_TOKEN")
    stub_request(:post, fm_url(host: host, database: database) + "/sessions").to_return_fm(token: token)
  end
end

RSpec.configure do |config|
  config.include RequestStubs
end
