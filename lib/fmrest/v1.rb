# frozen_string_literal: true

require "fmrest/v1/connection"
require "fmrest/v1/paths"
require "fmrest/v1/container_fields"
require "fmrest/v1/utils"
require "fmrest/v1/dates"
require "fmrest/v1/auth"

module FmRest
  module V1
    extend Connection
    extend Paths
    extend ContainerFields
    extend Utils
    extend Dates
    extend Auth

    autoload :TokenSession, "fmrest/v1/token_session"
    autoload :RaiseErrors, "fmrest/v1/raise_errors"
    autoload :TypeCoercer, "fmrest/v1/type_coercer"
  end
end
