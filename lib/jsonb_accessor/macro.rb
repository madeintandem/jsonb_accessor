# frozen_string_literal: true
module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, field_types)
        field_names = field_types.keys
        names_and_store_keys = field_types.each_with_object({}) do |(name, type), mapping|
          _type, options = Array(type)
          mapping[name.to_s] = (options.try(:delete, :store_key) || name).to_s
        end
        # Defines virtual attributes for each jsonb field.
        field_types.each do |name, type|
          attribute name, *type
        end

        # Setters are in a module to allow users to override them and still be able to use `super`.
        setters = Module.new do
          # Overrides the setter created by `attribute` above to make sure the jsonb attribute is kept in sync.
          names_and_store_keys.each do |name, store_key|
            define_method("#{name}=") do |value|
              super(value)
              new_values = (public_send(jsonb_attribute) || {}).merge(store_key => public_send(name))
              write_attribute(jsonb_attribute, new_values)
            end
          end

          # Overrides the jsonb attribute setter to make sure the jsonb fields are kept in sync.
          define_method("#{jsonb_attribute}=") do |value|
            indifferent_value = value.try(:with_indifferent_access) || {}
            value_with_store_keys = names_and_store_keys.each_with_object({}) do |(name, store_key), new_value|
              new_value[store_key] = indifferent_value[name]
            end

            super(value_with_store_keys)

            new_attributes = field_names.each_with_object({}) { |name, defaults| defaults[name] = nil }.merge(value || {})
            new_attributes.each { |name, new_value| write_attribute(name, new_value) }
          end

        end
        include setters

        # Makes sure new objects have the appropriate values in their jsonb fields.
        after_initialize do
          jsonb_values = public_send(jsonb_attribute) || {}

          # attributes  updated to reflect the jsonb_attribute
          jsonb_values.each do |store_key, value|
            name = names_and_store_keys.key(store_key)
            write_attribute(name, value) if name
          end

          # jsonb_attribute updated to reflect what's in attributes (includes default values)
          names_and_store_keys.each do |key, store_key|
            jsonb_values[store_key] = read_attribute(key) 
          end
          write_attribute(jsonb_attribute, jsonb_values)

          clear_changes_information if persisted?
        end

        # <jsonb_attribute>_where scope
        scope("#{jsonb_attribute}_where", lambda do |attributes|
          store_key_attributes = attributes.each_with_object({}) do |(name, value), new_attributes|
            store_key = names_and_store_keys[name.to_s]
            new_attributes[store_key] = value
          end
          jsonb_where(jsonb_attribute, store_key_attributes)
        end)
      end
    end
  end
end
