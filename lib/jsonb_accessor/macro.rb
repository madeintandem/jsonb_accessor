# frozen_string_literal: true
module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, field_types)
        field_names = field_types.keys

        field_types.each do |name, type|
          attribute name, *type
        end

        setters = Module.new do
          field_names.each do |name|
            define_method("#{name}=") do |value|
              super(value)
              new_values = (public_send(jsonb_attribute) || {}).merge(name => public_send(name))
              write_attribute(jsonb_attribute, new_values)
            end
          end

          define_method("#{jsonb_attribute}=") do |value|
            super(value)
            default_hash = field_names.each_with_object({}) do |name, defaults|
              defaults[name] = nil
            end
            default_hash.merge(public_send(jsonb_attribute) || {}).each do |name, attribute_value|
              write_attribute(name, attribute_value)
            end
          end
        end
        include setters

        after_initialize do
          jsonb_values = public_send(jsonb_attribute) || {}
          jsonb_values.each { |name, value| write_attribute(name, value) }
          clear_changes_information if persisted?
        end

        contains_scope = "#{jsonb_attribute}_contains"
        scope contains_scope, -> (attributes) { where("#{table_name}.#{jsonb_attribute} @> (?)::jsonb", attributes.to_json) }

        field_names.each do |name|
          scope("with_#{name}", -> (value) { public_send(contains_scope, name => value) })
        end
      end
    end
  end
end
