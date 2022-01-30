# frozen_string_literal: true

module JsonbAccessor
  class AttributeQueryMethods
    def initialize(klass)
      @klass = klass
    end

    def define(store_key_mapping_method_name, jsonb_attribute)
      return if klass.superclass.respond_to? store_key_mapping_method_name

      # <jsonb_attribute>_where scope
      klass.define_singleton_method "#{jsonb_attribute}_where" do |attributes|
        store_key_attributes = ::JsonbAccessor::Helpers.convert_keys_to_store_keys(attributes, all.model.public_send(store_key_mapping_method_name))
        jsonb_where(jsonb_attribute, store_key_attributes)
      end

      # <jsonb_attribute>_where_not scope
      klass.define_singleton_method "#{jsonb_attribute}_where_not" do |attributes|
        store_key_attributes = ::JsonbAccessor::Helpers.convert_keys_to_store_keys(attributes, all.model.public_send(store_key_mapping_method_name))
        jsonb_where_not(jsonb_attribute, store_key_attributes)
      end

      # <jsonb_attribute>_order scope
      klass.define_singleton_method "#{jsonb_attribute}_order" do |*args|
        ordering_options = args.extract_options!
        order_by_defaults = args.each_with_object({}) { |attribute, config| config[attribute] = :asc }
        store_key_mapping = all.model.public_send(store_key_mapping_method_name)

        order_by_defaults.merge(ordering_options).reduce(all) do |query, (name, direction)|
          key = store_key_mapping[name.to_s]
          order_query = jsonb_order(jsonb_attribute, key, direction)
          query.merge(order_query)
        end
      end
    end

    private

    attr_reader :klass
  end
end
