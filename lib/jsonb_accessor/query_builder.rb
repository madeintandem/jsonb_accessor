# frozen_string_literal: true

module JsonbAccessor
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

  IS_NUMBER_QUERY_ARGUMENTS = lambda do |arg|
    arg.is_a?(Hash) &&
      arg.keys.map(&:to_s).all? { |key| JsonbAccessor::NUMBER_OPERATORS.include?(key) }
  end

  IS_TIME_QUERY_ARGUMENTS = lambda do |arg|
    arg.is_a?(Hash) &&
      arg.keys.map(&:to_s).all? { |key| JsonbAccessor::TIME_OPERATORS.include?(key) }
  end

  CONVERT_NUMBER_RANGES = lambda do |attributes|
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

  CONVERT_TIME_RANGES = lambda do |attributes|
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

  CONVERT_RANGES = lambda do |attributes|
    [CONVERT_NUMBER_RANGES, CONVERT_TIME_RANGES].reduce(attributes) do |new_attributes, converter|
      converter.call(new_attributes)
    end
  end

  ORDER_DIRECTIONS = [:asc, :desc, "asc", "desc"].freeze

  module QueryBuilder
    extend ActiveSupport::Concern
    InvalidColumnName = Class.new(StandardError)
    InvalidFieldName = Class.new(StandardError)
    InvalidDirection = Class.new(StandardError)
    NotSupported = Class.new(StandardError)

    def self.validate_column_name!(query, column_name)
      if query.model.columns.none? { |column| column.name == column_name.to_s }
        raise InvalidColumnName, "a column named `#{column_name}` does not exist on the `#{query.model.table_name}` table"
      end
    end

    def self.validate_field_name!(query, column_name, field_name)
      store_keys = query.model.public_send("jsonb_store_key_mapping_for_#{column_name}").values
      if store_keys.exclude?(field_name.to_s)
        valid_field_names = store_keys.map { |key| "`#{key}`" }.join(", ")
        raise InvalidFieldName, "`#{field_name}` is not a valid field name, valid field names include: #{valid_field_names}"
      end
    end

    def self.validate_direction!(option)
      if ORDER_DIRECTIONS.exclude?(option)
        raise InvalidDirection, "`#{option}` is not a valid direction for ordering, only `asc` and `desc` are accepted"
      end
    end

    def self.convert_keys_to_store_keys(attributes, store_key_mapping)
      attributes.each_with_object({}) do |(name, value), new_attributes|
        store_key = store_key_mapping[name.to_s]
        new_attributes[store_key] = value
      end
    end

    included do
      scope(:jsonb_contains, lambda do |column_name, attributes|
        JsonbAccessor::QueryBuilder.validate_column_name!(all, column_name)
        where("#{table_name}.#{column_name} @> (?)::jsonb", attributes.to_json)
      end)

      scope(:jsonb_excludes, lambda do |column_name, attributes|
        JsonbAccessor::QueryBuilder.validate_column_name!(all, column_name)
        where.not("#{table_name}.#{column_name} @> (?)::jsonb", attributes.to_json)
      end)

      scope(:jsonb_number_where, lambda do |column_name, field_name, given_operator, value|
        JsonbAccessor::QueryBuilder.validate_column_name!(all, column_name)
        operator = JsonbAccessor::NUMBER_OPERATORS_MAP.fetch(given_operator.to_s)
        where("(#{table_name}.#{column_name} ->> ?)::float #{operator} ?", field_name, value)
      end)

      scope(:jsonb_number_where_not, lambda do |column_name, field_name, given_operator, value|
        JsonbAccessor::QueryBuilder.validate_column_name!(all, column_name)
        operator = JsonbAccessor::NUMBER_OPERATORS_MAP.fetch(given_operator.to_s)
        where.not("(#{table_name}.#{column_name} ->> ?)::float #{operator} ?", field_name, value)
      end)

      scope(:jsonb_time_where, lambda do |column_name, field_name, given_operator, value|
        JsonbAccessor::QueryBuilder.validate_column_name!(all, column_name)
        operator = JsonbAccessor::TIME_OPERATORS_MAP.fetch(given_operator.to_s)
        where("(#{table_name}.#{column_name} ->> ?)::timestamp #{operator} ?", field_name, value)
      end)

      scope(:jsonb_time_where_not, lambda do |column_name, field_name, given_operator, value|
        JsonbAccessor::QueryBuilder.validate_column_name!(all, column_name)
        operator = JsonbAccessor::TIME_OPERATORS_MAP.fetch(given_operator.to_s)
        where.not("(#{table_name}.#{column_name} ->> ?)::timestamp #{operator} ?", field_name, value)
      end)

      scope(:jsonb_where, lambda do |column_name, attributes|
        query = all
        contains_attributes = {}

        JsonbAccessor::CONVERT_RANGES.call(attributes).each do |name, value|
          case value
          when IS_NUMBER_QUERY_ARGUMENTS
            value.each { |operator, query_value| query = query.jsonb_number_where(column_name, name, operator, query_value) }
          when IS_TIME_QUERY_ARGUMENTS
            value.each { |operator, query_value| query = query.jsonb_time_where(column_name, name, operator, query_value) }
          else
            contains_attributes[name] = value
          end
        end

        query.jsonb_contains(column_name, contains_attributes)
      end)

      scope(:jsonb_where_not, lambda do |column_name, attributes|
        query = all
        excludes_attributes = {}

        attributes.each do |name, value|
          if value.is_a?(Range)
            raise NotSupported, "`jsonb_where_not` scope does not accept ranges as arguments. Given `#{value}` for `#{name}` field"
          end

          case value
          when IS_NUMBER_QUERY_ARGUMENTS
            value.each { |operator, query_value| query = query.jsonb_number_where_not(column_name, name, operator, query_value) }
          when IS_TIME_QUERY_ARGUMENTS
            value.each { |operator, query_value| query = query.jsonb_time_where_not(column_name, name, operator, query_value) }
          else
            excludes_attributes[name] = value
          end
        end

        excludes_attributes.empty? ? query : query.jsonb_excludes(column_name, excludes_attributes)
      end)

      scope(:jsonb_order, lambda do |column_name, field_name, direction|
        JsonbAccessor::QueryBuilder.validate_column_name!(all, column_name)
        JsonbAccessor::QueryBuilder.validate_field_name!(all, column_name, field_name)
        JsonbAccessor::QueryBuilder.validate_direction!(direction)
        order("(#{table_name}.#{column_name} -> '#{field_name}') #{direction}")
      end)
    end
  end
end
