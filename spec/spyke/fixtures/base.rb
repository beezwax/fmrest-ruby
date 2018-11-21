class FixtureBase < Spyke::Base
  include FmData::Spyke

  self.fmdata_config =
    {
      host:     "example.com",
      database: "TestDB",
      username: "test",
      password: "test"
    }.freeze
end
