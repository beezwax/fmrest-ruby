require "fmrest/v1/connection"
require "fmrest/v1/paths"
require "fmrest/v1/container_fields"
require "fmrest/v1/utils"

module FmRest
  module V1
    extend Connection
    extend Paths
    extend ContainerFields
    extend Utils
  end
end
