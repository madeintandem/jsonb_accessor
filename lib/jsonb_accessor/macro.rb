module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, *value_fields, **typed_fields)
        fields_map = JsonbAccessor::FieldsMap.new(value_fields, typed_fields)

        class_namespace = ClassBuilder.generate_class_namespace(name)
        attribute_namespace = ClassBuilder.generate_attribute_namespace(jsonb_attribute, class_namespace)
        nested_classes = ClassBuilder.generate_nested_classes(attribute_namespace, fields_map.nested_fields)

        singleton_class.send(:define_method, "#{jsonb_attribute}_classes") do
          nested_classes
        end

        delegate "#{jsonb_attribute}_classes", to: :class

        jsonb_attribute_initialization_method_name = "initialize_jsonb_attrs_for_#{jsonb_attribute}"

        define_method(jsonb_attribute_initialization_method_name) do
          jsonb_attribute_hash = send(jsonb_attribute) || {}
          fields_map.names.each do |field|
            send("#{field}=", jsonb_attribute_hash[field.to_s])
          end
        end

        after_initialize(jsonb_attribute_initialization_method_name)

        attribute_scope = lambda do |attributes|
          query_options = new(attributes).send(jsonb_attribute)
          fields = attributes.keys.map(&:to_s)
          query_options.delete_if { |key, value| fields.exclude?(key) }
          query_json = TypeHelper.type_cast_as_jsonb(query_options)
          where("#{table_name}.#{jsonb_attribute} @> ?", query_json)
        end
        jsonb_attribute_scope_name = "#{jsonb_attribute}_contains"
        scope jsonb_attribute_scope_name, attribute_scope

        fields_map.names.each do |field|
          scope "with_#{field}", -> (value) { send(jsonb_attribute_scope_name, field => value) }
        end

        typed_fields.each do |field, type|
          case type
          when :boolean
            scope "is_#{field}", -> { send("with_#{field}", true) }
            scope "not_#{field}", -> { send("with_#{field}", false) }
          end
        end

        jsonb_accessor_methods = Module.new do
          define_method("#{jsonb_attribute}=") do |value|
            write_attribute(jsonb_attribute, value)
            send(jsonb_attribute_initialization_method_name)
          end

          define_method(:reload) do |*args, &block|
            super(*args, &block)
            send(jsonb_attribute_initialization_method_name)
            self
          end
        end

        fields_map.typed_fields.each do |field, type|
          attribute(field.to_s, TypeHelper.fetch(type))

          jsonb_accessor_methods.instance_eval do
            define_method("#{field}=") do |value, *args, &block|
              super(value, *args, &block)
              new_jsonb_value = (send(jsonb_attribute) || {}).merge(field => attributes[field.to_s])
              write_attribute(jsonb_attribute, new_jsonb_value)
            end
          end
        end

        fields_map.nested_fields.each do |field, nested_attributes|
          attribute(field.to_s, TypeHelper.fetch(:value))

          jsonb_accessor_methods.instance_eval do
            define_method("#{field}=") do |value|
              instance_class = nested_classes[field]
              instance = cast_nested_field_value(value, instance_class, __method__)

              new_jsonb_value = (send(jsonb_attribute) || {}).merge(field.to_s => instance.attributes)
              write_attribute(jsonb_attribute, new_jsonb_value)
              super(instance)
            end
          end
        end

        include jsonb_accessor_methods
      end
    end
  end
end
