# frozen_string_literal: true

require "fmrest/v1/connection"
require "fmrest/v1/paths"
require "fmrest/v1/container_fields"
require "fmrest/v1/utils"
require "fmrest/v1/dates"

module FmRest
  module V1
    extend Connection
    extend Paths
    extend ContainerFields
    extend Utils
    extend Dates
  end
end
