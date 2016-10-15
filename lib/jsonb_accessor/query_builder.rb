module JsonbAccessor
  module QueryBuilder
    extend ActiveSupport::Concern

    included do
      scope(:jsonb_contains,
        -> (column_name, attributes) { where("#{table_name}.#{column_name} @> (?)::jsonb", attributes.to_json) })

      scope(:jsonb_is,
        -> (column_name, attributes) { where("#{table_name}.#{column_name} = (?)::jsonb", attributes.to_json) })
    end
  end
end
