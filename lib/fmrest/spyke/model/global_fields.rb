# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      module GlobalFields
        extend ::ActiveSupport::Concern

        class_methods do
          def set_globals(values_hash)
            connection.patch(FmRest::V1.globals_path, {
              globalFields: normalize_globals_hash(values_hash)
            })
          end

          private

          def normalize_globals_hash(hash)
            hash.each_with_object({}) do |(k, v), normalized|
              if v.kind_of?(Hash)
                v.each do |k2, v2|
                  normalized["#{k}::#{k2}"] = v2
                end
                next
              end

              unless V1.is_fully_qualified?(k.to_s)
                raise ArgumentError, "global fields must be given in fully qualified format (table name::field name)"
              end

              normalized[k] = v
            end
          end
        end
      end
    end
  end
end
