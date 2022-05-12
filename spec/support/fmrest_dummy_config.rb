# frozen_string_literal: true

FMREST_DUMMY_CONFIG = FmRest::ConnectionSettings.new({
  host:     "example.com",
  database: "TestDB",
  username: "test",
  password: "test",
  log:      !defined?(RSpec)
})
