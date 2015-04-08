module JsonbAccessor
  class NestedBase
    attr_accessor :attributes, :parent
    alias_method :to_h, :attributes

    delegate :[], to: :attributes
    delegate :nested_classes, :attribute_on_parent_name, to: :class

    def initialize(attributes = {})
      self.attributes = {}.with_indifferent_access

      nested_classes.keys.each do |key|
        send("#{key}=", nil)
      end

      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end

    def update_parent
      parent.send("#{attribute_on_parent_name}=", self) if parent
    end

    def []=(key, value)
      send("#{key}=", value)
    end

    def ==(suspect)
      self.class == suspect.class && attributes == suspect.attributes
    end
  end
end
