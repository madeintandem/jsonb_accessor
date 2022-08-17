# frozen_string_literal: true

require_relative "postgresql_adapter/query_builder"
require_relative "postgresql_adapter/attribute_query_methods"

module JsonbAccessor::Adapters::PostgresqlAdapter
  module_function

  ATTRIBUTE_TYPE = :jsonb

  def apply(model, attribute)
    model.include(JsonbAccessor::Adapters::PostgresqlAdapter::QueryBuilder)

    store_key_mapping_method_name = ::JsonbAccessor::Helpers.store_key_mapping_for_attribute(attribute)

    JsonbAccessor::Adapters::PostgresqlAdapter::AttributeQueryMethods.new(model).define(store_key_mapping_method_name, attribute)
  end
end

JsonbAccessor::Adapters::PostgisAdapter = JsonbAccessor::Adapters::PostgresqlAdapter
