# frozen_string_literal: true

module JsonbAccessor
  module Adapters
    module SqliteAdapter
      module QueryBuilder
        extend ActiveSupport::Concern

        class_methods do
          def attribute_sqlite_type(attribute)
            attribute_type = attribute_types.fetch(attribute.to_s).type
            {
              integer: :integer,
              json: :json,
              string: :char
            }.fetch(attribute_type.to_sym)
          end
        end

        included do
          scope(:jsonb_contains, lambda do |column_name, attributes|
            JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)

            attributes.inject(self) do |mod, (attribute, value)|
              mod.where("json_extract(#{mod.table_name}.options, ?) = ?", "$.#{attribute}", value)
            end
          end)

          scope(:jsonb_excludes, lambda do |column_name, attributes|
            JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)

            attributes.inject(self) do |mod, (attribute, value)|
              mod.where.not("json_extract(#{table_name}.#{column_name}, ?) = ?", "$.#{attribute}", value)
            end
          end)

          scope(:jsonb_number_where, lambda do |column_name, field_name, given_operator, value|
            JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
            operator = JsonbAccessor::QueryHelper::NUMBER_OPERATORS_MAP.fetch(given_operator.to_s)

            where("CAST((#{table_name}.#{column_name} ->> ?) as FLOAT) #{operator} ?", field_name, value)
          end)

          scope(:jsonb_number_where_not, lambda do |column_name, field_name, given_operator, value|
            JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
            operator = JsonbAccessor::QueryHelper::NUMBER_OPERATORS_MAP.fetch(given_operator.to_s)

            where.not("CAST((#{table_name}.#{column_name} ->> ?) as FLOAT) #{operator} ?", field_name, value)
          end)

          scope(:jsonb_time_where, lambda do |column_name, field_name, given_operator, value|
            JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
            operator = JsonbAccessor::QueryHelper::TIME_OPERATORS_MAP.fetch(given_operator.to_s)
            where("datetime((#{table_name}.#{column_name} ->> ?)) #{operator} ?", field_name, value)
          end)

          scope(:jsonb_time_where_not, lambda do |column_name, field_name, given_operator, value|
            JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
            operator = JsonbAccessor::QueryHelper::TIME_OPERATORS_MAP.fetch(given_operator.to_s)
            where.not("datetime((#{table_name}.#{column_name} ->> ?)) #{operator} ?", field_name, value)
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

          scope(:jsonb_order, lambda do |column_name, field_name, direction, field_type|
            JsonbAccessor::QueryHelper.validate_column_name!(all, column_name)
            JsonbAccessor::QueryHelper.validate_field_name!(all, column_name, field_name)
            JsonbAccessor::QueryHelper.validate_direction!(direction)
            field_type ||= "char"
            order(Arel.sql("CAST((#{table_name}.#{column_name} -> '#{field_name}') AS #{field_type}) #{direction}"))
          end)
        end
      end
    end
  end
end
