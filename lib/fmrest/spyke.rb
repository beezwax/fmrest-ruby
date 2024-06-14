# frozen_string_literal: true

require "spyke"
require "fmrest"
require "fmrest/spyke/spyke_formatter"
require "fmrest/spyke/model"
require "fmrest/spyke/base"

module FmRest
  module Spyke
    class << self
      # Sets the bahavior to use when creating an ORM query that can't be
      # logically satisified. See the section on querying in the README for
      # more info.
      #
      # Possible values:
      #
      # * `:raise` - Raise an `FmRest::Spyke::UnsatisfiableQuery` exception
      #   (inherits from `ArgumentError`) when the unsatisifiable query is
      #   created
      # * `:request_silent` - Silently allow the unsatisifiable query to go
      #   through, which will be translated in the Data API as `field:
      #   "1001..1000"` (ensures zero results)
      # * `:return_silent` - Silently return an empty resultset without issuing
      #   a request to the Data API. Use this option if you don't care about
      #   potential server-side side effects (e.g. scripts) of running a query.
      # * `:return_warn` - Same as `:return_silent` but will `warn()` about the
      #   unsatisifiable query
      # * `:request_warn`/`nil` (default) - Same as `:request_silent`, but will
      #   `warn()` about the unsatisifiable query
      attr_accessor :on_unsatisifiable_query
    end

    def self.included(base)
      base.include Model
    end
  end
end
