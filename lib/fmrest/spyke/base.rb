# frozen_string_literal: true

module FmRest
  module Spyke
    class Base < ::Spyke::Base
      include FmRest::Spyke::Model
    end

    class << self
      def Base(config = nil)
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
