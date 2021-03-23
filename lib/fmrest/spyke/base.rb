# frozen_string_literal: true

module FmRest
  module Spyke
    class Base < ::Spyke::Base
      include FmRest::Spyke::Model
    end
  end

  Layout = Spyke::Base

  # Shortcut for creating a Layout class and setting its FM layout name.
  #
  # @param layout [String] The FM layout to connect this class to
  #
  # @return [Class] A new subclass of `FmRest::Layout` with the FM layout
  #   setting already set.
  #
  def self.Layout(layout)
    Class.new(Layout) do
      self.layout layout
    end
  end
end
