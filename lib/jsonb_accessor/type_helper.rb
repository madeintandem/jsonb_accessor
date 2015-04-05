module JsonbAccessor
  module TypeHelper
    class << self
      def value
        ActiveRecord::Type::Value.new
      end

      def string
        ActiveRecord::Type::String.new
      end

      def integer
        ActiveRecord::Type::Integer.new
      end

      def boolean
        ActiveRecord::Type::Boolean.new
      end

      def date
        ActiveRecord::Type::Date.new
      end

      def datetime
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::DateTime.new
      end

      def decimal
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal.new
      end

      def time
        ActiveRecord::Type::Time.new
      end

      def float
        ActiveRecord::Type::Float.new
      end

      def array
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Value.new)
      end

      def string_array
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::String.new)
      end

      def integer_array
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Integer.new)
      end

      def boolean_array
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Boolean.new)
      end

      def date_array
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Date.new)
      end

      def datetime_array
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::DateTime.new)
      end

      def decimal_array
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal.new)
      end

      def time_array
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Time.new)
      end

      def float_array
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveRecord::Type::Float.new)
      end
    end
  end
end
