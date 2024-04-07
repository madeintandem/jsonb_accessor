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

    def deserialize_value(value, attribute_type)
      return value if value.blank?

      if attribute_type == :datetime
        value = if value.is_a?(Array)
                  value.map { |v| parse_date(v) }
                else
                  parse_date(value)
                end
      end

      value
    end

    # Parse datetime based on the configured default_timezone
    def parse_date(datetime)
      if active_record_default_timezone == :utc
        Time.find_zone("UTC").parse(datetime).in_time_zone
      else
        Time.zone.parse(datetime)
      end
    end

    def define_attribute_name(json_attribute, name, prefix, suffix)
      accessor_prefix =
        case prefix
        when String, Symbol
          "#{prefix}_"
        when TrueClass
          "#{json_attribute}_"
        else
          ""
        end
      accessor_suffix =
        case suffix
        when String, Symbol
          "_#{suffix}"
        when TrueClass
          "_#{json_attribute}"
        else
          ""
        end

      "#{accessor_prefix}#{name}#{accessor_suffix}"
    end
  end
end
