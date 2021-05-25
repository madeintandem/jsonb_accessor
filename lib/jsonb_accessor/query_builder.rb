# frozen_string_literal: true

module JsonbAccessor
  module QueryBuilder
    extend ActiveSupport::Concern

    included do
      scope(:jsonb_contains, lambda do |column_name, attributes|
        JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
        where("#{table_name}.#{column_name} @> (?)::jsonb", attributes.to_json)
      end)

      scope(:jsonb_excludes, lambda do |column_name, attributes|
        JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
        where.not("#{table_name}.#{column_name} @> (?)::jsonb", attributes.to_json)
      end)

      scope(:jsonb_number_where, lambda do |column_name, field_name, given_operator, value|
        JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
        operator = JsonbAccessor::QueryHelper::NUMBER_OPERATORS_MAP.fetch(given_operator.to_s)
        where("(#{table_name}.#{column_name} ->> ?)::float #{operator} ?", field_name, value)
      end)

      scope(:jsonb_number_where_not, lambda do |column_name, field_name, given_operator, value|
        JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
        operator = JsonbAccessor::QueryHelper::NUMBER_OPERATORS_MAP.fetch(given_operator.to_s)
        where.not("(#{table_name}.#{column_name} ->> ?)::float #{operator} ?", field_name, value)
      end)

      scope(:jsonb_time_where, lambda do |column_name, field_name, given_operator, value|
        JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
        operator = JsonbAccessor::QueryHelper::TIME_OPERATORS_MAP.fetch(given_operator.to_s)
        where("(#{table_name}.#{column_name} ->> ?)::timestamptz #{operator} ?", field_name, value)
      end)

      scope(:jsonb_time_where_not, lambda do |column_name, field_name, given_operator, value|
        JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
        operator = JsonbAccessor::QueryHelper::TIME_OPERATORS_MAP.fetch(given_operator.to_s)
        where.not("(#{table_name}.#{column_name} ->> ?)::timestamptz #{operator} ?", field_name, value)
      end)

      scope(:jsonb_where, lambda do |column_name, attributes|
        query = all
        contains_attributes = {}

        JsonbAccessor::QueryHelper.convert_ranges(attributes).each do |name, value|
          if JsonbAccessor::QueryHelper.number_query_arguments?(value)
            value.each { |operator, query_value| query = query.jsonb_number_where(column_name, name, operator, query_value) }
          elsif JsonbAccessor::QueryHelper.time_query_arguments?(value)
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
          raise JsonbAccessor::QueryHelper::NotSupported, "`jsonb_where_not` scope does not accept ranges as arguments. Given `#{value}` for `#{name}` field" if value.is_a?(Range)

          if JsonbAccessor::QueryHelper.number_query_arguments?(value)
            value.each { |operator, query_value| query = query.jsonb_number_where_not(column_name, name, operator, query_value) }
          elsif JsonbAccessor::QueryHelper.time_query_arguments?(value)
            value.each { |operator, query_value| query = query.jsonb_time_where_not(column_name, name, operator, query_value) }
          else
            excludes_attributes[name] = value
          end
        end

        excludes_attributes.empty? ? query : query.jsonb_excludes(column_name, excludes_attributes)
      end)

      scope(:jsonb_order, lambda do |column_name, field_name, direction|
        JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
        JsonbAccessor::QueryHelper.validate_field_name!(all, column_name, field_name)
        JsonbAccessor::QueryHelper.validate_direction!(direction)
        order(Arel.sql("(#{table_name}.#{column_name} -> '#{field_name}') #{direction}"))
      end)
    end
  end
end
