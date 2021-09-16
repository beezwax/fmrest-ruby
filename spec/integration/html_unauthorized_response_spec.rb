# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Unauthorized (401) response with text/html content-type" do
  # Objective: to test that we don't crash if the Data API responds with
  # text/html instead of application/json
  #
  it "requests a session" do
    settings = {
      host: "example.com",
      database: "test",
      username: "bob",
      password: "secret"
    }

    auth_stub =
      stub_session_login(host: settings[:host], database: settings[:database])

    stub_request(:get, "https://example.com/")
      .to_return(
        status: 401,
        body: "<html></html>",
        headers: {
          "Content-Type" => "text/html"
        }
      )

    connection = FmRest::V1.build_connection(settings)

    expect { connection.get("/") }.to raise_error(FmRest::APIError::AccountError, /HTTP 401: Unauthorized/)

    # The first time there's no token stored, so the TokenSession middleware
    # will try to get one.
    # The second time the GET / request results in a 401, so there's a second
    # attempt at init'ing a session.
    expect(auth_stub).to have_been_requested.twice
  end
end
