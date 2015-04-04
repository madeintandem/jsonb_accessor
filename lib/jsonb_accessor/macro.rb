module JsonbAccessor
  module Macro
    module ClassMethods
      TYPES = {
        value: -> { ActiveRecord::Type::Value.new },
        string: -> { ActiveRecord::Type::String.new },
        integer: -> { ActiveRecord::Type::Integer.new },
        boolean: -> { ActiveRecord::Type::Boolean.new },
        date: -> { ActiveRecord::Type::Date.new },
        datetime: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::DateTime.new },
        decimal: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal.new },
        time: -> { ActiveRecord::Type::Time.new },
        float: -> { ActiveRecord::Type::Float.new },
        array: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Value.new) },
        string_array: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::String.new) },
        integer_array: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Integer.new) },
        boolean_array: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Boolean.new) },
        date_array: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Date.new) },
        datetime_array: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::DateTime.new) },
        decimal_array: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal.new) },
        time_array: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Time.new) },
        float_array: -> { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Float.new) }
      }

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

        all_fields.each do |field, type|
          attribute(field.to_s, TYPES[type].call)

          define_method("#{field}=") do |value, *args, &block|
            super(value, *args, &block)
            send("#{jsonb_attribute}=", (send(jsonb_attribute) || {}).merge(field => attributes[field.to_s]))
          end
        end
      end
    end
  end
end
