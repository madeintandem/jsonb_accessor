# frozen_string_literal: true

module JsonbAccessor
  module Helpers
    module_function

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

    # Returns the store_key_mapping for the given attribute
    def store_key_mapping_for_attribute(attribute)
      "jsonb_store_key_mapping_for_#{attribute}"
    end

    def apply_json_accessor_adapter_to_model(model, attribute)
      json_accessor_adapter_for_model(model).apply(model, attribute)
    end

    def attribute_type_for_model(model)
      json_accessor_adapter_for_model(model)::ATTRIBUTE_TYPE
    end

    def json_accessor_adapter_for_model(model)
      adapter_name = connection_adapter_from_model(model).capitalize
      adapter_name = "::JsonbAccessor::Adapters::#{adapter_name}Adapter"

      return adapter_name.constantize if const_defined?(adapter_name)

      ::JsonbAccessor::Adapters::BaseAdapter
    end

    def connection_adapter_from_model(model)
      connection = model.connection
      connection.adapter_name.downcase.to_sym
    end
  end
end
