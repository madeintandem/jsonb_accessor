module JsonbAccessor
  module Macro
    class << self
      def group_attributes(value_fields, typed_fields)
        value_fields_hash = process_value_fields(value_fields)

        typed_fields.each_with_object(nested: {}, typed: value_fields_hash) do |(attribute_name, type_or_nested), grouped_attributes|
          group = type_or_nested.is_a?(Hash) ? grouped_attributes[:nested] : grouped_attributes[:typed]
          group[attribute_name] = type_or_nested
        end
      end

      def process_value_fields(value_fields)
        value_fields.each_with_object({}) do |value_field, hash_for_value_fields|
          hash_for_value_fields[value_field] = :value
        end
      end
    end

    module ClassMethods
      def jsonb_accessor(jsonb_attribute, *value_fields, **typed_fields)
        all_fields = Macro.group_attributes(value_fields, typed_fields)
        nested_fields, typed_fields = all_fields.values_at(:nested, :typed)

        class_namespace = Module.new
        attribute_namespace = Module.new
        JsonbAccessor.const_set(name, class_namespace)
        class_namespace.const_set(jsonb_attribute.to_s.camelize, attribute_namespace)

        nested_classes = ClassBuilder.generate_nested_classes(attribute_namespace, nested_fields)

        singleton_class.send(:define_method, "#{jsonb_attribute}_classes") do
          nested_classes
        end

        delegate "#{jsonb_attribute}_classes", to: :class

        define_method(:initialize_jsonb_attrs) do
          jsonb_attribute_hash = send(jsonb_attribute) || {}
          (typed_fields.keys + nested_fields.keys).each do |field|
            send("#{field}=", jsonb_attribute_hash[field.to_s])
          end
        end

        after_initialize :initialize_jsonb_attrs

        jsonb_setters = Module.new

        typed_fields.each do |field, type|
          attribute(field.to_s, TypeHelper.fetch(type))

          jsonb_setters.instance_eval do
            define_method("#{field}=") do |value, *args, &block|
              super(value, *args, &block)
              new_jsonb_value = (send(jsonb_attribute) || {}).merge(field => attributes[field.to_s])
              send("#{jsonb_attribute}=", new_jsonb_value)
            end
          end
        end

        nested_fields.each do |field, nested_attributes|
          attribute(field.to_s, TypeHelper.fetch(:value))

          jsonb_setters.instance_eval do
            define_method("#{field}=") do |value|
              instance_class = nested_classes[field]

              case value
              when instance_class
                instance = value
              when Hash
                instance = instance_class.new(value)
              when nil
                instance = instance_class.new
              else
                raise UnknownValue, "unable to set value '#{value}' is not a hash, `nil`, or an instance of #{instance_class} in #{__method__}"
              end

              instance.parent = self
              new_jsonb_value = (send(jsonb_attribute) || {}).merge(field => instance.attributes)
              send("#{jsonb_attribute}=", new_jsonb_value)
              super(instance)
            end
          end
        end

        include jsonb_setters
      end
    end
  end
end
