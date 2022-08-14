# frozen_string_literal: true

module JsonbAccessor
  module Helpers
    module_function

    # Include the correct query_builder on the model
    def include_query_builder_on_model(model)
      connection = model.connection
      adapter_type = connection.adapter_name.downcase.to_sym
      return unless ::JsonbAccessor::QueryBuilder::SUPPORTED_ADAPTERS.include?(adapter_type)

      model.include(::JsonbAccessor::QueryBuilder)
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
  end
end
