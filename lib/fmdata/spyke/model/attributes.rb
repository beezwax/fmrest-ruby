module FmData
  module Spyke
    module Model
      module Attributes
        extend ::ActiveSupport::Concern

        include ::ActiveModel::Dirty
        include ::ActiveModel::ForbiddenAttributesProtection

        included do
          # Keep mod_id as a separate, custom accessor
          attr_accessor :mod_id

          # Prevent the creation of plain (no prefix/suffix) attribute methods
          # when calling ActiveModels' define_attribute_method, otherwise it
          # will define an `attribute` method which overrides the one provided
          # by Spyke
          self.attribute_method_matchers.shift

          # ActiveModel::Dirty methods for id
          define_attribute_method(:id)

          # Keep track of attribute mappings so we can get the FM field names
          # for changed attributes
          class_attribute :mapped_attributes, instance_writer: false,
                                              default: ::ActiveSupport::HashWithIndifferentAccess.new.freeze

          class << self; private :mapped_attributes=; end
        end

        class_methods do
          # Similar to Spyke::Base.attributes, but allows defining attribute
          # methods that map to FM attributes with different names.
          #
          # Example:
          #
          #   class Person < Spyke::Base
          #     include FmData::Spyke::Model
          #
          #     attributes first_name: "FstName", last_name: "LstName"
          #   end
          #
          #   p = Person.new
          #   p.first_name = "Jojo"
          #   p.attributes # => { "FstName" => "Jojo" }
          #
          def attributes(*attrs)
            if attrs.length == 1 && attrs.first.kind_of?(Hash)
              attrs.first.each { |from, to| _fmdata_define_attribute(from, to) }
            else
              attrs.each { |attr| _fmdata_define_attribute(attr, attr) }
            end
          end

          private

          # Override Spyke::Base.new_or_return (private), called whenever
          # loading records from the HTTP API, so we can reset dirty info on
          # freshly loaded records
          #
          # See: https://github.com/balvig/spyke/blob/master/lib/spyke/http.rb
          #
          def new_or_return(attributes_or_object, *_)
            # In case of an existing Spyke object return it as is so that we
            # don't accidentally remove dirty data from associations
            return super if attributes_or_object.is_a?(::Spyke::Base)
            super.tap { |record| record.clear_changes_information }
          end

          def _fmdata_attribute_methods_container
            @fmdata_attribute_methods_container ||= Module.new.tap { |mod| include mod }
          end

          def _fmdata_define_attribute(from, to)
            # We use a setter here instead of injecting the hash key/value pair
            # directly with #[]= so that we don't change the mapped_attributes
            # hash on the parent class. The resulting hash is frozen for the
            # same reason.
            self.mapped_attributes = mapped_attributes.merge(from => to).freeze

            _fmdata_attribute_methods_container.module_eval do
              define_method(from) do
                attribute(to)
              end

              define_method(:"#{from}=") do |value|
                send("#{from}_will_change!") unless value == send(from)
                set_attribute(to, value)
              end
            end

            # Define ActiveModel::Dirty's methods
            define_attribute_method(from)
          end
        end

        def id=(value)
          id_will_change! unless value == id
          super
        end

        def save
          super.tap do |r|
            next unless r
            changes_applied
            portals.each(&:parent_changes_applied)
          end
        end

        def reload
          super.tap { |r| clear_changes_information }
        end

        # Override to_params to return FM Data API's expected JSON format, and
        # including only modified fields
        #
        def to_params
          params = { fieldData: changed_params_not_embedded_in_url }
          params[:modId] = mod_id if mod_id

          portal_data = serialize_portals
          params[:portalData] = portal_data unless portal_data.empty?

          params
        end

        # ActiveModel::Dirty since version 5.2 assumes that if there's an
        # @attributes instance variable set we must be using ActiveRecord, so
        # we override the instance variable name used by Spyke to avoid issues.
        #
        # TODO: Submit a pull request to Spyke so this isn't needed
        #
        def attributes
          @_spyke_attributes
        end

        # In addition to the comments above on `attributes`, this also adds
        # support for forbidden attributes
        #
        def attributes=(new_attributes)
          @_spyke_attributes ||= ::Spyke::Attributes.new(scope.params)
          use_setters(sanitize_for_mass_assignment(new_attributes)) if new_attributes && !new_attributes.empty?
        end

        protected

        def serialize_for_portal(portal)
          params =
            changed_params.except(:id).transform_keys do |key|
              "#{portal.attribute_prefix}::#{key}"
            end

          params[:recordId] = id if id
          params[:modId] = mod_id if mod_id

          params
        end

        private

        def serialize_portals
          portal_data = {}

          portals.each do |portal|
            portal.each do |portal_record|
              next unless portal_record.changed?
              portal_params = portal_data[portal.portal_key] ||= []
              portal_params << portal_record.serialize_for_portal(portal)
            end
          end

          portal_data
        end

        def changed_params
          attributes.to_params.slice(*mapped_changed)
        end

        def changed_params_not_embedded_in_url
          params_not_embedded_in_url.slice(*mapped_changed)
        end

        def mapped_changed
          mapped_attributes.values_at(*changed)
        end

        # Use known mapped_attributes for inspect
        #
        def inspect_attributes
          mapped_attributes.except(primary_key).map do |k, v|
            "#{k}: #{attribute(v).inspect}"
          end.join(', ')
        end
      end
    end
  end
end
