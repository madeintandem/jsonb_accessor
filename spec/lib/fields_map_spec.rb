# frozen_string_literal: true
require "spec_helper"

RSpec.describe JsonbAccessor::FieldsMap do
  let(:value_fields) { [:foo, :bar] }
  let(:typed_fields) { { reviewed_at: :date_time, price: :float } }
  let(:nested_field) { { field: :float } }
  let(:nested_fields) { { nested: nested_field } }
  subject { JsonbAccessor::FieldsMap.new(value_fields, nested_fields.merge(typed_fields)) }

  it { is_expected.to attr_accessorize(:nested_fields) }
  it { is_expected.to attr_accessorize(:typed_fields) }

  describe "#initialize" do
    context "typed fields" do
      it "is set to a hash containing explicitly typed fields" do
        typed_fields.each do |key, value|
          expect(subject.typed_fields[key]).to eq(value)
        end
      end

      it "is set to a hash containing implicitly typed value fields" do
        value_fields.each do |field_name|
          expect(subject.typed_fields[field_name]).to eq(:value)
        end
      end

      it "does not contain nested fields" do
        expect(subject.typed_fields).to_not have_key(:nested)
      end
    end

    context "nested fields" do
      it "is set to a hash of all the nested fields" do
        expect(subject.nested_fields).to eq(nested_fields)
      end
    end
  end

  describe "#names" do
    it "is all of the field names" do
      expect(subject.names).to match_array([:nested, :reviewed_at, :price, :foo, :bar])
    end
  end
end
