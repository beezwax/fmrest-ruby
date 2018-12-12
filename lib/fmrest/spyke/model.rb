require "fmdata/spyke/model/connection"
require "fmdata/spyke/model/uri"
require "fmdata/spyke/model/attributes"
require "fmdata/spyke/model/associations"
require "fmdata/spyke/model/orm"

module FmData
  module Spyke
    module Model
      extend ::ActiveSupport::Concern

      include Connection
      include Uri
      include Attributes
      include Associations
      include Orm

      included do
        attr_accessor :mod_id
      end
    end
  end
end
