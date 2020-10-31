# frozen_string_literal: true

module FmRest
  module Spyke
    class Base < ::Spyke::Base
      include FmRest::Spyke::Model
    end
  end
end
