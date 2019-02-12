require "fmrest/spyke/model/connection"
require "fmrest/spyke/model/uri"
require "fmrest/spyke/model/attributes"
require "fmrest/spyke/model/associations"
require "fmrest/spyke/model/orm"
require "fmrest/spyke/model/container_fields"

module FmRest
  module Spyke
    module Model
      extend ::ActiveSupport::Concern

      include Connection
      include Uri
      include Attributes
      include Associations
      include Orm
      include ContainerFields

      included do
        attr_accessor :mod_id
      end
    end
  end
end
