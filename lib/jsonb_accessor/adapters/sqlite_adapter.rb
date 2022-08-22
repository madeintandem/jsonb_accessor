# frozen_string_literal: true

require_relative "sqlite_adapter/query_builder"
require_relative "sqlite_adapter/attribute_query_methods"

module JsonbAccessor::Adapters::SqliteAdapter
  module_function

  ATTRIBUTE_TYPE = :json

  def apply(model, attribute)
    model.include(::JsonbAccessor::Adapters::SqliteAdapter::QueryBuilder)

    store_key_mapping_method_name = ::JsonbAccessor::Helpers.store_key_mapping_for_attribute(attribute)

    JsonbAccessor::Adapters::SqliteAdapter::AttributeQueryMethods.new(model).define(store_key_mapping_method_name, attribute)
  end
end
