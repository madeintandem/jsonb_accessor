# frozen_string_literal: true
module JsonbAccessor
  GREATER_THAN = ">".freeze
  GREATER_THAN_OR_EQUAL_TO = ">=".freeze
  LESS_THAN = "<".freeze
  LESS_THAN_OR_EQUAL_TO = "<=".freeze

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

  TIME_OPERATORS_MAP = {
    "after" => GREATER_THAN,
    "before" => LESS_THAN
  }.freeze

  module QueryBuilder
    extend ActiveSupport::Concern

    included do
      scope(:jsonb_contains,
        -> (column_name, attributes) { where("#{table_name}.#{column_name} @> (?)::jsonb", attributes.to_json) })

      scope(:jsonb_is,
        -> (column_name, attributes) { where("#{table_name}.#{column_name} = (?)::jsonb", attributes.to_json) })

      scope(:jsonb_number_query, lambda do |column_name, field_name, given_operator, value|
        operator = JsonbAccessor::NUMBER_OPERATORS_MAP.fetch(given_operator.to_s)
        where("(#{table_name}.#{column_name} ->> ?)::float #{operator} ?", field_name, value)
      end)

      scope(:jsonb_time_query, -> (column_name, field_name, given_operator, value) do
        operator = JsonbAccessor::TIME_OPERATORS_MAP.fetch(given_operator.to_s)
        where("(#{table_name}.#{column_name} ->> ?)::timestamp #{operator} ?", field_name, value)
      end)
    end
  end
end
