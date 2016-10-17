# frozen_string_literal: true
module JsonbAccessor
  module QueryBuilder
    extend ActiveSupport::Concern

    included do
      scope(:jsonb_contains,
        -> (column_name, attributes) { where("#{table_name}.#{column_name} @> (?)::jsonb", attributes.to_json) })

      scope(:jsonb_is,
        -> (column_name, attributes) { where("#{table_name}.#{column_name} = (?)::jsonb", attributes.to_json) })

      scope(:jsonb_number_query,
        -> (column_name, field_name, operator, value) { where("(#{table_name}.#{column_name} ->> ?)::float #{operator} ?", field_name, value) })
    end
  end
end
