# frozen_string_literal: true

module FmRest
  module Spyke
    class Base < ::Spyke::Base
      include FmRest::Spyke::Model
    end

    class << self
      def Base(config = nil)
        warn "[DEPRECATION] Inheriting from `FmRest::Spyke::Base(config)` is deprecated and will be removed, inherit from `FmRest::Spyke::Base` (without arguments) and use `fmrest_config=` instead"

        if config
          return Class.new(::FmRest::Spyke::Base) do
                   self.fmrest_config = config
                 end
        end

        ::FmRest::Spyke::Base
      end
    end
  end
end
