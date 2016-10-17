module JsonbAccessor
  UnknownValue = Class.new(StandardError)
  CLASS_PREFIX = "JA"

  module ClassBuilder
    class << self
      def generate_class(namespace, new_class_name, attribute_definitions)
        fields_map = JsonbAccessor::FieldsMap.new([], attribute_definitions)
        klass = generate_new_class(new_class_name, fields_map, namespace)
        nested_classes = generate_nested_classes(klass, fields_map.nested_fields)

        define_class_methods(klass, nested_classes, new_class_name)
        define_attributes_and_data_types(klass, fields_map)
        define_typed_accessors(klass, fields_map)
        define_nested_accessors(klass, fields_map)

        klass
      end

      def generate_nested_classes(klass, nested_attributes)
        nested_attributes.each_with_object({}) do |(attribute_name, nested_attrs), nested_classes|
          nested_classes[attribute_name] = generate_class(klass, attribute_name, nested_attrs)
        end
      end

      def generate_class_namespace(name)
        class_name = CLASS_PREFIX + name.gsub(CONSTANT_SEPARATOR, "")
        if JsonbAccessor.constants.any? { |c| c.to_s == class_name }
          class_namespace = JsonbAccessor.const_get(class_name)
        else
          class_namespace = Module.new
          JsonbAccessor.const_set(class_name, class_namespace)
        end
        class_namespace
      end

      def generate_attribute_namespace(attribute_name, class_namespace)
        attribute_namespace = Module.new
        name = generate_constant_name(attribute_name)
        class_namespace.const_set(name, attribute_namespace)
      end

      private

      def define_nested_accessors(klass, fields_map)
        klass.class_eval do
          fields_map.nested_fields.keys.each do |attribute_name|
            attr_reader attribute_name

            define_method("#{attribute_name}=") do |value|
              instance_class = nested_classes[attribute_name]
              instance = cast_nested_field_value(value, instance_class, __method__)

              instance_variable_set("@#{attribute_name}", instance)
              attributes[attribute_name] = instance.attributes
              update_parent
            end
          end
        end
      end

      def define_typed_accessors(klass, fields_map)
        klass.class_eval do
          fields_map.typed_fields.keys.each do |attribute_name|
            define_method(attribute_name) { attributes[attribute_name] }

            cast_method_name = ActiveRecord::VERSION::MAJOR == 5 ? :cast : :type_cast_from_user
            define_method("#{attribute_name}=") do |value|
              cast_value = attributes_and_data_types[attribute_name].public_send(cast_method_name, value)
              attributes[attribute_name] = cast_value
              update_parent
            end
          end
        end
      end

      def define_attributes_and_data_types(klass, fields_map)
        klass.send(:define_method, :attributes_and_data_types) do
          @attributes_and_data_types ||= fields_map.typed_fields.each_with_object({}) do |(name, type), attrs_and_data_types|
            attrs_and_data_types[name] = TypeHelper.fetch(type)
          end
        end
      end

      def define_class_methods(klass, nested_classes, attribute_name)
        klass.singleton_class.send(:define_method, :nested_classes) { nested_classes }
        klass.singleton_class.send(:define_method, :attribute_on_parent_name) { attribute_name }
      end

      def generate_new_class(new_class_name, fields_map, namespace)
        klass = Class.new(NestedBase)
        new_class_name_camelized = generate_constant_name(new_class_name)
        namespace.const_set(new_class_name_camelized, klass)
      end

      def generate_constant_name(attribute_name)
        "#{CLASS_PREFIX}#{attribute_name.to_s.camelize}"
      end
    end
  end
end
