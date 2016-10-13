# frozen_string_literal: true
module JsonbAccessor
  CONSTANT_SEPARATOR = "::"
  module TypeHelper
    ARRAY_MATCHER = /_array\z/
    UnknownType = Class.new(StandardError)

    class << self
      def fetch(type)
        case type
        when :array
          new_array(value)
        when ARRAY_MATCHER
          fetch_active_record_array_type(type)
        when :value
          value
        else
          fetch_active_record_type(type)
        end
      end

      def type_cast_as_jsonb(suspect)
        type_cast_hash = jsonb.type_cast_from_user(suspect)
        jsonb.type_cast_for_database(type_cast_hash)
      end

      private

      def jsonb
        @jsonb ||= fetch(:jsonb)
      end

      def fetch_active_record_array_type(type)
        subtype = type.to_s.sub(ARRAY_MATCHER, "")
        new_array(fetch_active_record_type(subtype))
      end

      def fetch_active_record_type(type)
        class_name = type.to_s.camelize
        klass = value_descendants.find do |ar_type|
          ar_type.to_s.split(CONSTANT_SEPARATOR).last == class_name
        end

        if klass
          klass.new
        else
          raise JsonbAccessor::TypeHelper::UnknownType
        end
      end

      def value_descendants
        grouped_types = ActiveRecord::Type::Value.descendants.group_by do |ar_type|
          !!ar_type.to_s.match(ActiveRecord::ConnectionAdapters::PostgreSQL::OID.to_s)
        end

        grouped_types[true] + grouped_types[false]
      end

      def value
        ActiveRecord::Type::Value.new
      end

      def new_array(subtype)
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(subtype)
      end
    end
  end
end
