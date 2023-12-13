# frozen_string_literal: true

require "fmrest/spyke/model/orm"

module FmRest
  module Spyke
    module Model
      # Extends Spyke models with support for mapped attributes,
      # `ActiveModel::Dirty` and forbidden attributes (e.g. Rails'
      # `params.permit`).
      #
      module Attributes
        extend ::ActiveSupport::Concern

        include Orm # Needed to extend custom save and reload

        include ::ActiveModel::Dirty
        include ::ActiveModel::ForbiddenAttributesProtection

        included do
          # Prevent the creation of plain (no prefix/suffix) attribute methods
          # when calling ActiveModels' define_attribute_method, otherwise it
          # will define an `attribute` method which overrides the one provided
          # by Spyke
          if respond_to? :attribute_method_patterns
            # ActiveModel >= 7.1
            attribute_method_patterns.shift
          else
            # ActiveModel < 7.1
            attribute_method_matchers.shift
          end

          # Keep track of attribute mappings so we can get the FM field names
          # for changed attributes
          class_attribute :mapped_attributes, instance_writer: false, instance_predicate: false

          # class_attribute supports a :default option since ActiveSupport 5.2,
          # but we want to support previous versions too so we set the default
          # manually instead
          self.mapped_attributes = ::ActiveSupport::HashWithIndifferentAccess.new.freeze

          class << self; private :mapped_attributes=; end

          set_callback :save, :after, :changes_applied_after_save
        end

        class_methods do
          # Spyke override
          #
          # Similar to Spyke::Base.attributes, but allows defining attribute
          # methods that map to FM attributes with different names.
          #
          # @example
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

          # Spyke override (private)
          #
          # Called whenever loading records from the HTTP API, so we can reset
          # dirty info on freshly loaded records
          #
          # See: https://github.com/balvig/spyke/blob/master/lib/spyke/http.rb
          #
          def new_or_return(attributes_or_object, *_)
            # In case of an existing Spyke object return it as is so that we
            # don't accidentally remove dirty data from associations
            return super if attributes_or_object.is_a?(::Spyke::Base)
            super.tap do |record|
              # In ActiveModel 4.x #clear_changes_information is a private
              # method, so we need to call it with send() in that case, but
              # keep calling it normally for AM5+
              if record.respond_to?(:clear_changes_information)
                record.clear_changes_information
              else
                record.send(:clear_changes_information)
              end
            end
          end

          def _fmrest_attribute_methods_container
            @fmrest_attribute_methods_container ||= Module.new.tap { |mod| include mod }
          end

          def _fmrest_define_attribute(from, to)
            if existing_method = ((method_defined?(from) || private_method_defined?(from)) && from) ||
                                 ((method_defined?("#{from}=") || private_method_defined?("#{from}=")) && "#{from}=")

              raise ArgumentError, "You tried to define an attribute named `#{from}' on `#{name}', but this will generate a instance method `#{existing_method}', which is already defined by FmRest::Layout."
            end

            # We use a setter here instead of injecting the hash key/value pair
            # directly with #[]= so that we don't change the mapped_attributes
            # hash on the parent class. The resulting hash is frozen for the
            # same reason.
            self.mapped_attributes = mapped_attributes.merge(from => to.to_s).freeze

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

        # Spyke override -- Adds AM::Dirty support
        #
        def reload(*args)
          super.tap { |r| clear_changes_information }
        end

        # Spyke override -- Adds support for forbidden attributes (i.e. Rails'
        # `params.permit`, etc.)
        #
        def attributes=(new_attributes)
          @spyke_attributes ||= ::Spyke::Attributes.new(scope.params)
          return unless new_attributes && !new_attributes.empty?
          use_setters(sanitize_for_mass_assignment(new_attributes))
        end

        private

        def changed_params
          attributes.to_params.slice(*mapped_changed)
        end

        def mapped_changed
          mapped_attributes.values_at(*changed)
        end

        # Spyke override (private) -- Use known mapped_attributes for inspect
        #
        def inspect_attributes
          mapped_attributes.except(primary_key).map do |k, v|
            "#{k}: #{attribute(v).inspect}"
          end.join(', ')
        end

        def changes_applied_after_save
          changes_applied
          portals.each(&:parent_changes_applied)
        end
      end
    end
  end
end
