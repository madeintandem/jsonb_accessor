module JsonbAccessor
  class NestedBase
    attr_accessor :attributes, :parent
    alias_method :to_h, :attributes

    delegate :[], to: :attributes
    delegate :nested_classes, to: :class

    def initialize(attributes = {})
      self.attributes = {}.with_indifferent_access

      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end

    def []=(key, value)
      send("#{key}=", value)
    end
  end
end
