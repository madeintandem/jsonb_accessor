# frozen_string_literal: true
require "spec_helper"

RSpec.describe JsonbAccessor::TypeHelper do
  describe "#fetch" do
    subject { JsonbAccessor::TypeHelper.fetch(type) }

    context "unknown type" do
      let(:type) { :does_not_exist }

      it "raises an error" do
        expect { subject }.to raise_error(JsonbAccessor::TypeHelper::UnknownType)
      end
    end

    context "value" do
      let(:type) { :value }

      it "is a value type" do
        expect(subject.class).to eq(ActiveRecord::Type::Value)
      end
    end

    context "array" do
      let(:type) { :array }

      it "is an postgres array type" do
        expect(subject.class).to eq(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array)
      end

      it "has a subtype of value" do
        expect(subject.subtype.class).to eq(ActiveRecord::Type::Value)
      end
    end

    context "other recognized value" do
      context "named matches ActiveRecord::Type::Value subclass" do
        let(:type) { :big_integer }

        it "is the ActiveRecord::Type namespaced class" do
          expect(subject.class).to eq(ActiveRecord::Type::BigInteger)
        end
      end

      context "namespaced in ActiveRecord::ConnectionAdapters::PostgreSQL::OID" do
        let(:type) { :jsonb }

        it "is a ActiveRecord::ConnectionAdapters::PostgreSQL::OID namespaced class" do
          expect(subject.class).to eq(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb)
        end
      end

      context "namespaced in ActiveRecord::Type and ActiveRecord::ConnectionAdapters::PostgreSQL::OID" do
        let(:type) { :decimal }

        it "is the ActiveRecord::ConnectionAdapters::PostgreSQL::OID version" do
          expect(subject.class).to eq(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal)
        end
      end
    end

    context "typed array" do
      let(:type) { :decimal_array }

      it "is a postgres array type" do
        expect(subject.class).to eq(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array)
      end

      it "has the given subtype" do
        expect(subject.subtype.class).to eq(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal)
      end
    end
  end

  describe "#type_cast_as_jsonb" do
    let(:hash) { { foo: :bar } }
    subject do
      JsonbAccessor::TypeHelper.type_cast_as_jsonb(hash)
    end

    it "converts the hash to a json string" do
      expect(subject).to eq(%({"foo":"bar"}))
    end
  end
end
