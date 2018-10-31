require "support/webmock"

module RequestStubs
  def stub_session_login(host: "example.com", database: "TestDB", token: "MOCK_SESSION_TOKEN")
    stub_request(:post, "https://#{host}/fmi/data/v1/databases/#{database}/sessions").to_return_fm(token: token)
  end
end

RSpec.configure do |config|
  config.include RequestStubs
end
