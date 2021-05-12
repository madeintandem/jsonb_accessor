# frozen_string_literal: true

module JsonbAccessor
  module QueryHelper
    # Errors
    InvalidColumnName = Class.new(StandardError)
    InvalidFieldName = Class.new(StandardError)
    InvalidDirection = Class.new(StandardError)
    NotSupported = Class.new(StandardError)

    # Constants
    GREATER_THAN = ">"
    GREATER_THAN_OR_EQUAL_TO = ">="
    LESS_THAN = "<"
    LESS_THAN_OR_EQUAL_TO = "<="

    NUMBER_OPERATORS_MAP = {
      GREATER_THAN => GREATER_THAN,
      "greater_than" => GREATER_THAN,
      "gt" => GREATER_THAN,
      GREATER_THAN_OR_EQUAL_TO => GREATER_THAN_OR_EQUAL_TO,
      "greater_than_or_equal_to" => GREATER_THAN_OR_EQUAL_TO,
      "gte" => GREATER_THAN_OR_EQUAL_TO,
      LESS_THAN => LESS_THAN,
      "less_than" => LESS_THAN,
      "lt" => LESS_THAN,
      LESS_THAN_OR_EQUAL_TO => LESS_THAN_OR_EQUAL_TO,
      "less_than_or_equal_to" => LESS_THAN_OR_EQUAL_TO,
      "lte" => LESS_THAN_OR_EQUAL_TO
    }.freeze

    NUMBER_OPERATORS = NUMBER_OPERATORS_MAP.keys.freeze

    TIME_OPERATORS_MAP = {
      "after" => GREATER_THAN,
      "before" => LESS_THAN
    }.freeze

    TIME_OPERATORS = TIME_OPERATORS_MAP.keys.freeze

    ORDER_DIRECTIONS = [:asc, :desc, "asc", "desc"].freeze

    class << self
      def validate_column_name!(query, column_name)
        raise InvalidColumnName, "a column named `#{column_name}` does not exist on the `#{query.model.table_name}` table" if query.model.columns.none? { |column| column.name == column_name.to_s }
      end

      def validate_field_name!(query, column_name, field_name)
        store_keys = query.model.public_send("jsonb_store_key_mapping_for_#{column_name}").values
        if store_keys.exclude?(field_name.to_s)
          valid_field_names = store_keys.map { |key| "`#{key}`" }.join(", ")
          raise InvalidFieldName, "`#{field_name}` is not a valid field name, valid field names include: #{valid_field_names}"
        end
      end

      def validate_direction!(option)
        raise InvalidDirection, "`#{option}` is not a valid direction for ordering, only `asc` and `desc` are accepted" if ORDER_DIRECTIONS.exclude?(option)
      end

      def convert_keys_to_store_keys(attributes, store_key_mapping)
        attributes.each_with_object({}) do |(name, value), new_attributes|
          store_key = store_key_mapping[name.to_s]
          new_attributes[store_key] = value
        end
      end

      def number_query_arguments?(arg)
        arg.is_a?(Hash) && arg.keys.map(&:to_s).all? { |key| NUMBER_OPERATORS.include?(key) }
      end

      def time_query_arguments?(arg)
        arg.is_a?(Hash) && arg.keys.map(&:to_s).all? { |key| TIME_OPERATORS.include?(key) }
      end

      def convert_number_ranges(attributes)
        attributes.each_with_object({}) do |(name, value), new_attributes|
          is_range = value.is_a?(Range)

          new_attributes[name] = if is_range && value.first.is_a?(Numeric) && value.exclude_end?
                                   { greater_than_or_equal_to: value.first, less_than: value.end }
                                 elsif is_range && value.first.is_a?(Numeric)
                                   { greater_than_or_equal_to: value.first, less_than_or_equal_to: value.end }
                                 else
                                   value
                                 end
        end
      end

      def convert_time_ranges(attributes)
        attributes.each_with_object({}) do |(name, value), new_attributes|
          is_range = value.is_a?(Range)

          if is_range && (value.first.is_a?(Time) || value.first.is_a?(Date))
            start_time = value.first
            end_time = value.end
            new_attributes[name] = { before: end_time, after: start_time }
          else
            new_attributes[name] = value
          end
        end
      end

      def convert_ranges(attributes)
        %i[convert_number_ranges convert_time_ranges].reduce(attributes) do |new_attributes, converter_method|
          public_send(converter_method, new_attributes)
        end
      end
    end
  end
end
