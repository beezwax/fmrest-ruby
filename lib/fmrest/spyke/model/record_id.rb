# frozen_string_literal: true

require "fmrest/spyke/model/orm"

module FmRest
  module Spyke
    module Model
      module RecordID
        extend ::ActiveSupport::Concern

        included do
          # @return [Integer] the record's recordId
          attr_accessor :__record_id
          alias_method :record_id, :__record_id
          alias_method :id, :__record_id

          # @return [Integer] the record's modId
          attr_accessor :__mod_id
          alias_method :mod_id, :__mod_id

          # Get rid of Spyke's id= setter method, as we'll be using __record_id=
          # instead
          undef_method :id=

          # Tell Spyke that we want __record_id as the PK
          self.primary_key = :__record_id
        end

        def record_id?
          record_id.present?
        end

        def inspect
          "#<#{self.class} record_id: #{record_id.inspect} #{inspect_attributes}>"
        end

        private

        # Spyke Override
        def conflicting_ids?(attributes)
          false
        end
      end
    end
  end
end
