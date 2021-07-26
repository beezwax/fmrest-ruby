# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::Spyke::Model::Rescuable do
  let(:klass) do
    fmrest_spyke_class do
      extend(Module.new { def request(*args); raise args.first; end })
    end.tap { |c| c.include(described_class) }
  end

  it "allows catching exceptions raised by API calls" do
    canary = double
    expect(canary).to receive(:call).once

    klass.rescue_from FmRest::APIError::SystemError, with: -> { canary.call }

    klass.request(FmRest::APIError::SystemError.new(0, "Ouch!"))
  end

  describe ".rescue_account_error" do
    it "works as a shortcut for `rescue_from APIError::AccountError`" do
      canary = double
      expect(canary).to receive(:call).once

      klass.rescue_account_error { canary.call }

      klass.request(FmRest::APIError::AccountError.new(212, "Bad creds"))
    end
  end
end
