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

  module QueryBuilder
    extend ActiveSupport::Concern

    included do
      scope(:jsonb_contains,
        -> (column_name, attributes) { where("#{table_name}.#{column_name} @> (?)::jsonb", attributes.to_json) })

      scope(:jsonb_number_where, lambda do |column_name, field_name, given_operator, value|
        operator = JsonbAccessor::NUMBER_OPERATORS_MAP.fetch(given_operator.to_s)
        where("(#{table_name}.#{column_name} ->> ?)::float #{operator} ?", field_name, value)
      end)

      scope(:jsonb_time_where, lambda do |column_name, field_name, given_operator, value|
        operator = JsonbAccessor::TIME_OPERATORS_MAP.fetch(given_operator.to_s)
        where("(#{table_name}.#{column_name} ->> ?)::timestamp #{operator} ?", field_name, value)
      end)

      scope(:jsonb_where, lambda do |column_name, attributes|
        query = all
        contains_attributes = {}

        attributes.each do |name, value|
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
    end
  end
end
