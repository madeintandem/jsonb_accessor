module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, *fields)
        fields.each do |field|
          define_method(field) do
            (send(jsonb_attribute) || {})[field.to_s]
          end

          define_method("#{field}=") do |value|
            jsonb_attribute_value = (send(jsonb_attribute) || {}).merge(field => value)
            send("#{jsonb_attribute}=", jsonb_attribute_value)
          end
        end
      end
    end
  end
end
