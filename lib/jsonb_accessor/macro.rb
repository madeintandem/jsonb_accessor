# frozen_string_literal: true
module JsonbAccessor
  module Macro
    module ClassMethods
      def jsonb_accessor(jsonb_attribute, field_types)
        field_types.each do |name, type|
          attribute name, *type
        end

        setters = Module.new do
          field_types.keys.each do |name|
            define_method("#{name}=") do |value|
              super(value)
              new_values = (public_send(jsonb_attribute) || {}).merge(name => public_send(name))
              public_send("#{jsonb_attribute}=", new_values)
            end
          end
        end
        include setters

        after_initialize do
          jsonb_values = public_send(jsonb_attribute) || {}
          jsonb_values.each { |name, value| write_attribute(name, value) }
          clear_changes_information if persisted?
        end

        contains_scope = "#{jsonb_attribute}_contains"
        scope contains_scope, -> (attributes) do
          where("#{table_name}.#{jsonb_attribute} @> (?)::jsonb", attributes.to_json)
        end

        field_types.keys.each do |name|
          scope "with_#{name}", -> (value) do
            public_send(contains_scope, name => value)
          end
        end
      end
    end
  end
end
