# frozen_string_literal: true
module JsonbAccessor
  class FieldsMap
    attr_accessor :nested_fields, :typed_fields

    def initialize(value_fields, typed_and_nested_fields)
      grouped_fields = extract_typed_and_nested_fields(typed_and_nested_fields)
      nested_fields, typed_fields = grouped_fields.values_at(:nested, :typed)

      self.typed_fields = implicitly_typed_fields(value_fields).merge(typed_fields)
      self.nested_fields = nested_fields
    end

    def names
      typed_fields.keys + nested_fields.keys
    end

    private

    def implicitly_typed_fields(value_fields)
      value_fields.each_with_object({}) do |field_name, implicitly_typed_fields|
        implicitly_typed_fields[field_name] = :value
      end
    end

    def extract_typed_and_nested_fields(typed_and_nested_fields)
      typed_and_nested_fields.each_with_object(nested: {}, typed: {}) do |(attribute_name, type_or_nested), grouped_attributes|
        group = type_or_nested.is_a?(Hash) ? grouped_attributes[:nested] : grouped_attributes[:typed]
        group[attribute_name] = type_or_nested
      end
    end
  end
end
