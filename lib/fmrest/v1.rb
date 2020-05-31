# frozen_string_literal: true

require "fmrest/v1/connection"
require "fmrest/v1/paths"
require "fmrest/v1/container_fields"
require "fmrest/v1/utils"
require "fmrest/v1/dates"

module FmRest
  module V1
    DEFAULT_DATE_FORMAT = "MM/dd/yyyy"
    DEFAULT_TIME_FORMAT = "HH:mm:ss"
    DEFAULT_TIMESTAMP_FORMAT = "#{DEFAULT_DATE_FORMAT} #{DEFAULT_TIME_FORMAT}"

    extend Connection
    extend Paths
    extend ContainerFields
    extend Utils
    extend Dates
  end
end
