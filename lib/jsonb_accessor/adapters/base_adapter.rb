# frozen_string_literal: true

# Loaded but not included. It is meant for inheriting from
require_relative "base_adapter/attribute_query_methods"

module JsonbAccessor::Adapters::BaseAdapter
  module_function

  ATTRIBUTE_TYPE = :json

  def apply(_model, _attribute); end
end
