# frozen_string_literal: true
module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, field_types)
        field_names = field_types.keys

        # Defines virtual attributes for each jsonb field.
        field_types.each do |name, type|
          attribute name, *type
        end

        # Setters are in a module to allow users to override them and still be able to use `super`.
        setters = Module.new do
          # Overrides the setter created by `attribute` above to make sure the jsonb attribute is kept in sync.
          field_names.each do |name|
            define_method("#{name}=") do |value|
              super(value)
              new_values = (public_send(jsonb_attribute) || {}).merge(name => public_send(name))
              write_attribute(jsonb_attribute, new_values)
            end
          end

          # Overrides the jsonb attribute setter to make sure the jsonb fields are kept in sync.
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

        # Makes sure new objects have the appropriate values in their jsonb fields.
        after_initialize do
          jsonb_values = public_send(jsonb_attribute) || {}
          jsonb_values.each { |name, value| write_attribute(name, value) }
          clear_changes_information if persisted?
        end

        # From here down we're defining scopes.
        contains_scope = "#{jsonb_attribute}_contains"
        scope contains_scope, -> (attributes) { where("#{table_name}.#{jsonb_attribute} @> (?)::jsonb", attributes.to_json) }

        field_names.each do |name|
          scope("with_#{name}", -> (value) { public_send(contains_scope, name => value) })
        end
      end
    end
  end
end
