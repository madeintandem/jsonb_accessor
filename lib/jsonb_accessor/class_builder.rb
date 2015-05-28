module JsonbAccessor
  UnknownValue = Class.new(StandardError)
  CLASS_PREFIX = "JA"

  module ClassBuilder
    class << self
      def generate_class(namespace, new_class_name, attribute_definitions)
        grouped_attributes = group_attributes(attribute_definitions)

        klass = Class.new(NestedBase)
        new_class_name_camelized = "#{CLASS_PREFIX}#{new_class_name.to_s.camelize}"
        namespace.const_set(new_class_name_camelized, klass)
        nested_classes = generate_nested_classes(klass, grouped_attributes[:nested])

        klass.class_eval do
          singleton_class.send(:define_method, :nested_classes) { nested_classes }
          singleton_class.send(:define_method, :attribute_on_parent_name) { new_class_name }

          define_method(:attributes_and_data_types) do
            @attributes_and_data_types ||= grouped_attributes[:typed].each_with_object({}) do |(name, type), attrs_and_data_types|
              attrs_and_data_types[name] = TypeHelper.fetch(type)
            end
          end

          grouped_attributes[:typed].keys.each do |attribute_name|
            define_method(attribute_name) { attributes[attribute_name] }

            define_method("#{attribute_name}=") do |value|
              cast_value = attributes_and_data_types[attribute_name].type_cast_from_user(value)
              attributes[attribute_name] = cast_value
              update_parent
            end
          end

          grouped_attributes[:nested].keys.each do |attribute_name|
            attr_reader attribute_name

            define_method("#{attribute_name}=") do |value|
              instance_class = nested_classes[attribute_name]

              case value
              when instance_class
                instance = instance_class.new(value.attributes)
              when Hash
                instance = instance_class.new(value)
              when nil
                instance = instance_class.new
              else
                raise UnknownValue, "unable to set value '#{value}' is not a hash, `nil`, or an instance of #{instance_class} in #{__method__}"
              end

              instance.parent = self
              instance_variable_set("@#{attribute_name}", instance)
              attributes[attribute_name] = instance.attributes
              update_parent
            end
          end
        end
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

      private

      def group_attributes(attributes)
        attributes.each_with_object(nested: {}, typed: {}) do |(name, type_or_nested), grouped_attributes|
          group = type_or_nested.is_a?(Hash) ? grouped_attributes[:nested] : grouped_attributes[:typed]
          group[name] = type_or_nested
        end
      end
    end
  end
end
