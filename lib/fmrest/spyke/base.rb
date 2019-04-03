# frozen_string_literal: true

module FmRest
  module Spyke
    class Base < ::Spyke::Base
      include FmRest::Spyke::Model
    end

    class << self
      def Base(config = {})
        Class.new(::FmRest::Spyke::Base) do
          self.fmrest_config = config
        end
      end
    end
  end
end
