# frozen_string_literal: true

require "spec_helper"

RSpec.describe FmRest::Spyke::Model::Rescuable do
  let(:klass) do
    fmrest_spyke_class do
      extend(
        Module.new do
          # Override Model.request so it raises its first argument as an
          # exception, or call the given block if given
          def request(*args)
            return yield if block_given?
            raise args.first
          end
        end
      )
    end.tap do |c|
      # Include Rescueable mixin (in a tap block so we have access to
      # described_class)
      # This will wrap the above request method and call it with super
      c.include(described_class)
    end
  end

  describe ".rescue_from" do
    it "allows catching exceptions raised by API calls" do
      canary = double
      expect(canary).to receive(:call).once

      klass.rescue_from FmRest::APIError::SystemError, with: -> { canary.call }

      klass.request(FmRest::APIError::SystemError.new(0, "Ouch!"))
    end

    it "retries if :retry is thrown" do
      klass.rescue_from ArgumentError, with: -> { throw :retry }

      error = "A"

      expect do
        klass.request { raise ArgumentError.new(error = error.succ) }
      end.to raise_error("C")
    end

    it "doesn't retry by default" do
      klass.rescue_from ArgumentError, with: -> {}
      expect { klass.request(ArgumentError) }.to_not raise_error
    end
  end

  describe ".rescue_account_error" do
    it "works as a shortcut for `rescue_from APIError::AccountError`, with forced retry" do
      canary = double
      expect(canary).to receive(:call).once

      klass.rescue_account_error { canary.call }

      expect { klass.request(FmRest::APIError::AccountError.new(212, "Bad creds")) }.to raise_error(FmRest::APIError::AccountError)
    end
  end
end
