# frozen_string_literal: true

module JsonbAccessor
  module Helpers
    module_function

    # Include the correct query_builder on the model
    def include_query_builder_on_model(model)
      return unless ::JsonbAccessor::QueryBuilder::SUPPORTED_ADAPTERS.include?(adapter_type_for_model(model))

      model.include(::JsonbAccessor::QueryBuilder)
    end

    def define_attribute_query_methods(model, store_key_mapping_method_name, json_attribute)
      return unless ::JsonbAccessor::AttributeQueryMethods::SUPPORTED_ADAPTERS.include?(adapter_type_for_model(model))

      ::JsonbAccessor::AttributeQueryMethods.new(model).define(store_key_mapping_method_name, json_attribute)
    end

    def attribute_type_for_model(model)
      %i[postgresql postgis].include?(adapter_type_for_model(model)) ? :jsonb : :json
    end

    def active_record_default_timezone
      ActiveRecord.try(:default_timezone) || ActiveRecord::Base.default_timezone
    end

    # Replaces all keys in `attributes` that have a defined store_key with the store_key
    def convert_keys_to_store_keys(attributes, store_key_mapping)
      attributes.stringify_keys.transform_keys do |key|
        store_key_mapping[key] || key
      end
    end

    # Replaces all keys in `attributes` that have a defined store_key with the named key (alias)
    def convert_store_keys_to_keys(attributes, store_key_mapping)
      convert_keys_to_store_keys(attributes, store_key_mapping.invert)
    end

    def adapter_type_for_model(model)
      connection = model.connection
      connection.adapter_name.downcase.to_sym
    end
  end
end
