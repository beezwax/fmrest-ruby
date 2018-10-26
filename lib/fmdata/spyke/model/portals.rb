require "fmdata/spyke/portal"

module FmData
  module Spyke
    module Model
      module Portals
        extend ::ActiveSupport::Concern

        class_methods do
          # Based on has_many, but creates a special Portal association instead
          #
          def portal(name, options = {})
            create_association(name, Portal, options)

            define_method "#{name.to_s.singularize}_ids=" do |ids|
              attributes[name] = []
              ids.reject(&:blank?).each { |id| association(name).build(id: id) }
            end

            define_method "#{name.to_s.singularize}_ids" do
              association(name).map(&:id)
            end
          end
        end
      end
    end
  end
end

