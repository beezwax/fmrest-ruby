# frozen_string_literal: true

require "fmrest/spyke/model/connection"
require "fmrest/spyke/model/uri"
require "fmrest/spyke/model/record_id"
require "fmrest/spyke/model/attributes"
require "fmrest/spyke/model/serialization"
require "fmrest/spyke/model/associations"
require "fmrest/spyke/model/orm"
require "fmrest/spyke/model/container_fields"
require "fmrest/spyke/model/global_fields"
require "fmrest/spyke/model/http"
require "fmrest/spyke/model/auth"

module FmRest
  module Spyke
    module Model
      extend ::ActiveSupport::Concern

      include Connection
      include URI
      include RecordID
      include Attributes
      include Serialization
      include Associations
      include Orm
      include ContainerFields
      include GlobalFields
      include Http
      include Auth
    end
  end
end
