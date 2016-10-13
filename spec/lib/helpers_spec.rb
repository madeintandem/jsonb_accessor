# frozen_string_literal: true
require "spec_helper"

RSpec.describe JsonbAccessor::Helpers do
  let(:dummy_class) do
    Class.new do
      attr_accessor :attributes, :parent

      def initialize(attributes = {})
        self.attributes = attributes
      end
    end
  end
  subject { Object.new.extend(JsonbAccessor::Helpers) }

  describe "#cast_nested_field_value" do
    it "assigns itself as the new object's parent" do
      result = subject.cast_nested_field_value(nil, dummy_class, :foo)
      expect(result.parent).to eq(subject)
    end

    context "value is the given class" do
      let(:value) { dummy_class.new(foo: :bar) }
      let(:result) { subject.cast_nested_field_value(value, dummy_class, :foo) }

      it "is a new instance of the class with the same attributes" do
        expect(result).to be_a(dummy_class)
        expect(result.attributes).to eq(value.attributes)
        expect(result).to_not equal(value)
      end
    end

    context "value is a hash" do
      let(:value) { { foo: :bar } }
      let(:result) { subject.cast_nested_field_value(value, dummy_class, :foo) }

      it "is a new instance of the class with the same attributes as the given hash" do
        expect(result).to be_a(dummy_class)
        expect(result.attributes).to eq(value)
      end
    end

    context "value is nil" do
      let(:result) { subject.cast_nested_field_value(nil, dummy_class, :foo) }

      it "is a new instance of the class with empty attributes" do
        expect(result).to be_a(dummy_class)
        expect(result.attributes).to eq({})
      end
    end

    context "value is something else" do
      it "raises an error" do
        expect do
          subject.cast_nested_field_value(Object.new, dummy_class, :foo)
        end.to raise_error(JsonbAccessor::UnknownValue)
      end
    end
  end
end
