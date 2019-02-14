module FmRest
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
                                              instance_predicate: false,
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
          #     include FmRest::Spyke::Model
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
              attrs.first.each { |from, to| _fmrest_define_attribute(from, to) }
            else
              attrs.each { |attr| _fmrest_define_attribute(attr, attr) }
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

          def _fmrest_attribute_methods_container
            @fmrest_attribute_methods_container ||= Module.new.tap { |mod| include mod }
          end

          def _fmrest_define_attribute(from, to)
            # We use a setter here instead of injecting the hash key/value pair
            # directly with #[]= so that we don't change the mapped_attributes
            # hash on the parent class. The resulting hash is frozen for the
            # same reason.
            self.mapped_attributes = mapped_attributes.merge(from => to).freeze

            _fmrest_attribute_methods_container.module_eval do
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

        def save(*_args)
          super.tap do |r|
            next unless r.present?
            changes_applied
            portals.each(&:parent_changes_applied)
          end
        end

        def reload
          super.tap { |r| clear_changes_information }
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

        private

        def changed_params
          attributes.to_params.slice(*mapped_changed)
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
