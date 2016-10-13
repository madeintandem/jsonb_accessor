# frozen_string_literal: true
module JsonbAccessor
  module Helpers
    def cast_nested_field_value(value, klass, method_name)
      case value
      when klass
        instance = klass.new(value.attributes)
      when Hash
        instance = klass.new(value)
      when nil
        instance = klass.new
      else
        raise UnknownValue, "unable to set value '#{value}' is not a hash, `nil`, or an instance of #{klass} in #{method_name}"
      end

      instance.parent = self
      instance
    end
  end
end
