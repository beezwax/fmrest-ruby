# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      # Modifies Spyke models to use `__record_id` instead of `id` as the
      # "primary key" method, so that we can map a model class to a FM layout
      # with a field named `id` without clobbering it.
      #
      # The `id` reader method still maps to the record ID for backwards
      # compatibility and because Spyke hardcodes its use at various points
      # through its codebase, but it can be safely overwritten (e.g. to map to
      # a FM field).
      #
      # The recommended way to deal with a layout that maps an `id` attribute
      # is to remap it in the model to something else, e.g. `unique_id`.
      #
      module RecordID
        extend ::ActiveSupport::Concern

        included do
          # @return [Integer] the record's recordId
          attr_reader :__record_id
          alias_method :record_id, :__record_id
          alias_method :id, :__record_id

          # @return [Integer] the record's modId
          attr_reader :__mod_id
          alias_method :mod_id, :__mod_id

          # Get rid of Spyke's id= setter method, as we'll be using __record_id=
          # instead
          undef_method :id=

          # Tell Spyke that we want __record_id as the PK
          self.primary_key = :__record_id
        end

        # Sets the recordId and converts it to integer if it's not nil
        #
        # @param value [String, Integer, nil] The new recordId
        #
        # @return [Integer] the record's recordId
        def __record_id=(value)
          @__record_id = value.nil? ? nil : value.to_i
        end

        # Sets the modId and converts it to integer if it's not nil
        #
        # @param value [String, Integer, nil] The new modId
        #
        # @return [Integer] the record's modId
        def __mod_id=(value)
          @__mod_id = value.nil? ? nil : value.to_i
        end

        def __record_id?
          __record_id.present?
        end
        alias_method :record_id?, :__record_id?
        alias_method :persisted?, :__record_id?

        # Spyke override -- Use `__record_id` instead of `id`
        #
        def hash
          __record_id.hash
        end

        # Spyke override -- Renders class string with layout name and
        # `record_id`.
        #
        # @return [String] A string representation of the class
        #
        def inspect
          "#<#{self.class}(layout: #{self.class.layout}) record_id: #{__record_id.inspect} #{inspect_attributes}>"
        end

        # Spyke override -- Use `__record_id` instead of `id`
        #
        # @param id [Integer] The id of the record to destroy
        #
        def destroy(id = nil)
          new(__record_id: id).destroy
        end

        private

        # Spyke override (private)
        #
        def conflicting_ids?(attributes)
          false
        end
      end
    end
  end
end
