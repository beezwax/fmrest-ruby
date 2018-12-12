module FmData
  module Spyke
    class Base < ::Spyke::Base
      include FmData::Spyke::Model
    end

    class << self
      def Base(config = {})
        Class.new(::FmData::Spyke::Base) do
          self.fmdata_config = config
        end
      end
    end
  end
end
