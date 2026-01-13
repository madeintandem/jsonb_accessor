# frozen_string_literal: true

module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, global_options = {}, **definitions)
        names_and_store_keys = {}
        names_and_defaults = {}
        names_and_attribute_names = {}

        definitions.each do |name, value|
          args = Array(value)
          options = args.last.is_a?(Hash) ? args.pop : {}

          # Determine store keys and default values for each field
          names_and_store_keys[name.to_s] = (options.delete(:store_key) || name).to_s
          names_and_defaults[name.to_s] = options.delete(:default) unless options[:default].nil?

          prefix = options.delete(:prefix) || global_options[:prefix]
          suffix = options.delete(:suffix) || global_options[:suffix]
          attribute_name = JsonbAccessor::Helpers.define_attribute_name(jsonb_attribute, name, prefix, suffix)

          # Define virtual attributes for each field
          names_and_attribute_names[name.to_s] = attribute_name
          attribute attribute_name, *args, **options
        end

        store_key_mapping_method_name = "jsonb_store_key_mapping_for_#{jsonb_attribute}"
        attribute_name_mapping_method_name = "jsonb_attribute_name_mapping_for_#{jsonb_attribute}"
        # Defines methods on the model class
        class_methods = Module.new do
          # Allows us to get a mapping of field names to store keys scoped to the column
          define_method(store_key_mapping_method_name) do
            superclass_mapping = superclass.try(store_key_mapping_method_name) || {}
            superclass_mapping.merge(names_and_store_keys)
          end

          # Allows us to get a mapping of field names to attribute names scoped to the column
          define_method(attribute_name_mapping_method_name) do
            superclass_mapping = superclass.try(attribute_name_mapping_method_name) || {}
            superclass_mapping.merge(names_and_attribute_names)
          end
        end
        # We extend with class methods here so we can use the results of methods it defines to define more useful methods later
        extend class_methods

        # Get store keys to default values mapping
        store_keys_and_defaults = JsonbAccessor::Helpers.convert_keys_to_store_keys(names_and_defaults, public_send(store_key_mapping_method_name))

        # Define jsonb_defaults_mapping_for_<jsonb_attribute>
        defaults_mapping_method_name = "jsonb_defaults_mapping_for_#{jsonb_attribute}"
        class_methods.instance_eval do
          define_method(defaults_mapping_method_name) do
            superclass_mapping = superclass.try(defaults_mapping_method_name) || {}
            superclass_mapping.merge(store_keys_and_defaults)
          end
        end

        all_defaults_mapping = public_send(defaults_mapping_method_name)
        # Fields may have procs as default value. This means `all_defaults_mapping` may contain procs as values. To make this work
        # with the attributes API, we need to wrap `all_defaults_mapping` with a proc itself, making sure it returns a plain hash
        # each time it is evaluated.
        all_defaults_mapping_proc =
          if all_defaults_mapping.present?
            -> { all_defaults_mapping.transform_values { |value| value.respond_to?(:call) ? value.call : value }.to_h.compact }
          end
        attribute jsonb_attribute, :jsonb, default: all_defaults_mapping_proc if all_defaults_mapping_proc.present?

        # Setters are in a module to allow users to override them and still be able to use `super`.
        setters = Module.new do
          # Overrides the setter created by `attribute` above to make sure the jsonb attribute is kept in sync.
          names_and_store_keys.each do |name, store_key|
            attribute_name = names_and_attribute_names[name]

            define_method("#{attribute_name}=") do |value|
              super(value)

              # If enum was defined, take the value from the enum and not what comes out directly from the getter
              attribute_value = defined_enums[attribute_name].present? ? defined_enums[attribute_name][value] : public_send(attribute_name)

              # Rails always saves time based on `default_timezone`. Since #as_json considers timezone, manual conversion is needed
              if attribute_value.acts_like?(:time)
                attribute_value = (JsonbAccessor::Helpers.active_record_default_timezone == :utc ? attribute_value.utc : attribute_value.in_time_zone).strftime("%F %R:%S.%L")
              end

              new_values = (public_send(jsonb_attribute) || {}).merge(store_key => attribute_value)
              write_attribute(jsonb_attribute, new_values)
            end
          end

          # Overrides the jsonb attribute setter to make sure the jsonb fields are kept in sync.
          define_method("#{jsonb_attribute}=") do |value|
            value ||= {}
            names_to_store_keys = self.class.public_send(store_key_mapping_method_name)
            names_to_attribute_names = self.class.public_send(attribute_name_mapping_method_name)

            # this is the raw hash we want to save in the jsonb_attribute
            value_with_store_keys = JsonbAccessor::Helpers.convert_keys_to_store_keys(value, names_to_store_keys)
            write_attribute(jsonb_attribute, value_with_store_keys)

            # this maps attributes to values
            value_with_named_keys = JsonbAccessor::Helpers.convert_store_keys_to_keys(value, names_to_store_keys)

            empty_named_attributes = names_to_store_keys.transform_values { nil }
            empty_named_attributes.merge(value_with_named_keys).each do |name, attribute_value|
              # Only proceed if this attribute has been defined using `jsonb_accessor`.
              next unless names_to_store_keys.key?(name)

              attribute_name = names_to_attribute_names[name]
              write_attribute(attribute_name, attribute_value)
            end
          end
        end
        include setters

        # Makes sure new objects have the appropriate values in their jsonb fields.
        after_initialize do
          next unless has_attribute? jsonb_attribute

          jsonb_values = public_send(jsonb_attribute) || {}
          jsonb_values.each do |store_key, value|
            name = names_and_store_keys.key(store_key)
            attribute_name = names_and_attribute_names[name]

            next unless attribute_name

            write_attribute(
              attribute_name,
              JsonbAccessor::Helpers.deserialize_value(value, self.class.type_for_attribute(attribute_name).type)
            )
            clear_attribute_change(attribute_name) if persisted?
          end
        end

        JsonbAccessor::AttributeQueryMethods.new(self).define(store_key_mapping_method_name, jsonb_attribute)
      end
    end
  end
end
