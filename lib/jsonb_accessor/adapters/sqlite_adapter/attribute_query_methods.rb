# frozen_string_literal: true

module JsonbAccessor
  module Adapters
    module SqliteAdapter
      class AttributeQueryMethods < JsonbAccessor::Adapters::BaseAdapter::AttributeQueryMethods
        private

        def define_order(store_key_mapping_method_name, jsonb_attribute)
          klass.define_singleton_method "#{jsonb_attribute}_order" do |*args|
            ordering_options = args.extract_options!
            order_by_defaults = args.each_with_object({}) { |attribute, config| config[attribute] = :asc }
            store_key_mapping = all.model.public_send(store_key_mapping_method_name)

            order_by_defaults.merge(ordering_options).reduce(all) do |query, (name, direction)|
              key = store_key_mapping[name.to_s]
              field_type = attribute_sqlite_type(name)
              order_query = jsonb_order(jsonb_attribute, key, direction, field_type)
              query.merge(order_query)
            end
          end
        end
      end
    end
  end
end
