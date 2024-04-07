# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonbAccessor::Helpers do
  describe ".convert_keys_to_store_keys" do
    let(:attributes) { { foo: "bar", bar: "baz" } }
    let(:store_key_mapping) { { "foo" => "foo", "bar" => "b" } }
    let(:expected) { { "foo" => "bar", "b" => "baz" } }

    it "converts the keys of a given hash into store keys based on the given store key mapping" do
      expect(subject.convert_keys_to_store_keys(attributes, store_key_mapping)).to eq(expected)
    end
  end

  describe ".convert_store_keys_to_keys" do
    let(:attributes) { { foo: "bar", b: "baz" } }
    let(:store_key_mapping) { { "foo" => "foo", "bar" => "b" } }
    let(:expected) { { "foo" => "bar", "bar" => "baz" } }

    it "converts the keys of a given hash into named keys based on the given store key mapping" do
      expect(subject.convert_store_keys_to_keys(attributes, store_key_mapping)).to eq(expected)
    end
  end

  describe ".define_attribute_name" do
    let(:json_attribute) { :options }
    let(:name) { :foo }
    let(:prefix) { :pref }
    let(:suffix) { :suff }
    let(:expected) { "#{prefix}_#{name}_#{suffix}" }

    it "returns attribute name with prefix and suffix" do
      expect(subject.define_attribute_name(json_attribute, name, prefix, suffix)).to eq(expected)
    end

    context "when affixes is true class" do
      let(:prefix) { true }
      let(:suffix) { true }
      let(:expected) { "#{json_attribute}_#{name}_#{json_attribute}" }

      it "returns attribute name with json_attribute prefix and suffix" do
        expect(subject.define_attribute_name(json_attribute, name, prefix, suffix)).to eq(expected)
      end
    end

    context "when affixes is nil" do
      let(:prefix) { nil }
      let(:suffix) { nil }
      let(:expected) { name.to_s }

      it "returns attribute name without prefix and suffix" do
        expect(subject.define_attribute_name(json_attribute, name, prefix, suffix)).to eq(expected)
      end
    end
  end
end
