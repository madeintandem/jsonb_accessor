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
end
