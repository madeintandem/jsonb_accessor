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
        new_array(value)
      end

      def string_array
        new_array(string)
      end

      def integer_array
        new_array(integer)
      end

      def boolean_array
        new_array(boolean)
      end

      def date_array
        new_array(date)
      end

      def datetime_array
        new_array(datetime)
      end

      def decimal_array
        new_array(decimal)
      end

      def time_array
        new_array(time)
      end

      def float_array
        new_array(float)
      end

      private

      def new_array(subtype)
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(subtype)
      end
    end
  end
end
