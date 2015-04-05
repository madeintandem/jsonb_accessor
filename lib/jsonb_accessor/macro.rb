module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, *value_fields, **typed_fields)
        value_fields_hash = value_fields.each_with_object({}) do |value_field, hash_for_value_fields|
          hash_for_value_fields[value_field] = :value
        end

        all_fields = value_fields_hash.merge(typed_fields)

        define_method(:initialize_jsonb_attrs) do
          jsonb_attribute_hash = send(jsonb_attribute) || {}
          all_fields.keys.each do |field|
            send("#{field}=", jsonb_attribute_hash[field.to_s])
          end
        end

        after_initialize :initialize_jsonb_attrs

        jsonb_setters = Module.new

        all_fields.each do |field, type|
          attribute(field.to_s, TypeHelper.fetch(type))

          jsonb_setters.instance_eval do
            define_method("#{field}=") do |value, *args, &block|
              super(value, *args, &block)
              new_jsonb_value = (send(jsonb_attribute) || {}).merge(field => attributes[field.to_s])
              send("#{jsonb_attribute}=", new_jsonb_value)
            end
          end
        end

        include jsonb_setters
      end
    end
  end
end
