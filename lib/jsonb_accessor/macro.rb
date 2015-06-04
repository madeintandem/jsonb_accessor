module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, *value_fields, **typed_fields)
        fields_map = JsonbAccessor::FieldsMap.new(value_fields, typed_fields)
        class_namespace = ClassBuilder.generate_class_namespace(name)
        attribute_namespace = ClassBuilder.generate_attribute_namespace(jsonb_attribute, class_namespace)
        nested_classes = ClassBuilder.generate_nested_classes(attribute_namespace, fields_map.nested_fields)
        jsonb_attribute_initialization_method_name = "initialize_jsonb_attrs_for_#{jsonb_attribute}"
        jsonb_attribute_scope_name = "#{jsonb_attribute}_contains"

        singleton_class.send(:define_method, "#{jsonb_attribute}_classes") do
          nested_classes
        end

        delegate "#{jsonb_attribute}_classes", to: :class

        _initialize_jsonb_attrs(jsonb_attribute, fields_map, jsonb_attribute_initialization_method_name)
        _create_jsonb_attribute_scope_name(jsonb_attribute, jsonb_attribute_scope_name)
        _create_jsonb_scopes(jsonb_attribute, fields_map, jsonb_attribute_scope_name)
        _create_jsonb_accessor_methods(jsonb_attribute, jsonb_attribute_initialization_method_name, fields_map)
      end

      private

      def _initialize_jsonb_attrs(jsonb_attribute, fields_map, jsonb_attribute_initialization_method_name)
        define_method(jsonb_attribute_initialization_method_name) do
          jsonb_attribute_hash = send(jsonb_attribute) || {}
          fields_map.names.each do |field|
            send("#{field}=", jsonb_attribute_hash[field.to_s])
          end
        end
        after_initialize(jsonb_attribute_initialization_method_name)
      end

      def _create_jsonb_attribute_scope_name(jsonb_attribute, jsonb_attribute_scope_name)
        scope jsonb_attribute_scope_name, (lambda do |attributes|
                                             query_options = new(attributes).send(jsonb_attribute)
                                             fields = attributes.keys.map(&:to_s)
                                             query_options.delete_if { |key, value| fields.exclude?(key) }
                                             query_json = TypeHelper.type_cast_as_jsonb(query_options)
                                             where("#{table_name}.#{jsonb_attribute} @> ?", query_json)
                                           end)
      end

      def _create_jsonb_scopes(jsonb_attribute, fields_map, jsonb_attribute_scope_name)
        __create_jsonb_standard_scopes(fields_map, jsonb_attribute_scope_name)
        __create_jsonb_typed_scopes(jsonb_attribute, fields_map)
      end

      def __create_jsonb_standard_scopes(fields_map, jsonb_attribute_scope_name)
        fields_map.names.each do |field|
          scope "with_#{field}", -> (value) { send(jsonb_attribute_scope_name, field => value) }
        end
      end

      def __create_jsonb_typed_scopes(jsonb_attribute, fields_map)
        fields_map.typed_fields.each do |field, type|
          case type
          when :boolean
            ___create_jsonb_boolean_scopes(field)
          when :integer, :float, :decimal
            ___create_jsonb_numeric_scopes(field, type, jsonb_attribute)
          end
        end
      end

      def ___create_jsonb_boolean_scopes(field)
        scope "is_#{field}", -> { send("with_#{field}", true) }
        scope "not_#{field}", -> { send("with_#{field}", false) }
      end

      def ___create_jsonb_numeric_scopes(field, type, jsonb_attribute)
        scope "__numeric_#{field}_comparator", -> (value, operator) { where("((#{table_name}.#{jsonb_attribute}) ->> ?)::#{type} #{operator} ?", field, value) }
        scope "#{field}_lt", -> (value) { send("__numeric_#{field}_comparator", value, "<") }
        scope "#{field}_lte", -> (value) { send("__numeric_#{field}_comparator", value, "<=") }
        scope "#{field}_gte", -> (value) { send("__numeric_#{field}_comparator", value, ">=") }
        scope "#{field}_gt", -> (value) { send("__numeric_#{field}_comparator", value, ">") }
      end

      def _create_jsonb_accessor_methods(jsonb_attribute, jsonb_attribute_initialization_method_name, fields_map)
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

        __create_jsonb_typed_field_setters(jsonb_attribute, jsonb_accessor_methods, fields_map)
        __create_jsonb_nested_field_accessors(jsonb_attribute, jsonb_accessor_methods, fields_map)
        include jsonb_accessor_methods
      end

      def __create_jsonb_typed_field_setters(jsonb_attribute, jsonb_accessor_methods, fields_map)
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
      end

      def __create_jsonb_nested_field_accessors(jsonb_attribute, jsonb_accessor_methods, fields_map)
        fields_map.nested_fields.each do |field, nested_attributes|
          attribute(field.to_s, TypeHelper.fetch(:value))
          jsonb_accessor_methods.instance_eval do
            define_method("#{field}=") do |value|
              instance_class = send("#{jsonb_attribute}_classes")[field]
              instance = cast_nested_field_value(value, instance_class, __method__)

              new_jsonb_value = (send(jsonb_attribute) || {}).merge(field.to_s => instance.attributes)
              write_attribute(jsonb_attribute, new_jsonb_value)
              super(instance)
            end
          end
        end
      end
    end
  end
end
