require "spec_helper"

VALUE_FIELDS = [:count, :name, :price]
TYPED_FIELDS = {
  title: :string,
  name_value: :value,
  id_value: :value,
  external_id: :integer,
  admin: :boolean,
  approved_on: :date,
  reviewed_at: :datetime,
  precision: :decimal,
  reset_at: :time,
  amount_floated: :float
}
ALL_FIELDS = VALUE_FIELDS + TYPED_FIELDS.keys

class Product < ActiveRecord::Base
  jsonb_accessor :options, *VALUE_FIELDS, TYPED_FIELDS
end

RSpec.describe JsonbAccessor do
  it "has a version number" do
    expect(JsonbAccessor::VERSION).to_not be nil
  end

  it "is mixed into ActiveRecord::Base" do
    expect(ActiveRecord::Base.ancestors).to include(subject)
  end

  it "defines jsonb_accessor" do
    expect(ActiveRecord::Base).to respond_to(:jsonb_accessor)
  end

  context "value setters" do
    subject { Product.new }
    let(:name) { "Marty McFly" }
    let(:count) { 5 }
    let(:price) { 2.5 }

    before do
      subject.name = name
      subject.count = count
      subject.price = price
    end

    context "default value fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["name"]).to eq(name)
        expect(subject.options["count"]).to eq(count)
        expect(subject.options["price"]).to eq(price)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.name).to eq(name)
        expect(subject.count).to eq(count)
        expect(subject.price).to eq(price)
      end
    end
  end

  context "typed setters" do
    subject { Product.new }
    let(:title) { "Mister" }
    let(:id_value) { 1056 }
    let(:name_value) { "John McClane" }
    let(:external_id) { 456 }
    let(:admin) { true }
    let(:approved_on) { Date.new(2015, 3, 25) }
    let(:reviewed_at) { DateTime.new(2015, 3, 25, 6, 45, 33) }
    let(:precision) { 5.0023 }
    let(:reset_at) { Time.new(2015, 4, 5, 6, 7, 8) }
    let(:amount_floated) { 52.8892 }

    before do
      subject.title = title
      subject.id_value = id_value
      subject.name_value = name_value
      subject.external_id = external_id
      subject.admin = admin
      subject.approved_on = approved_on
      subject.reviewed_at = reviewed_at
      subject.precision = precision
      subject.reset_at = reset_at
      subject.amount_floated = amount_floated
    end

    context "string fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["title"]).to eq(title)
      end

      it "coerces the value" do
        subject.title = 5
        expect(subject.title).to eq("5")
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.title).to eq(title)
      end
    end

    context "value fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["id_value"]).to eq(id_value)
        expect(subject.options["name_value"]).to eq(name_value)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.name_value).to eq(name_value)
        expect(subject.id_value).to eq(id_value)
      end
    end

    context "integer fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["external_id"]).to eq(external_id)
      end

      it "coerces the value" do
        subject.external_id = "23"
        expect(subject.external_id).to eq(23)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.external_id).to eq(external_id)
      end
    end

    context "boolean fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["admin"]).to eq(admin)
      end

      ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES.each do |value|
        it "coerces the value to false when the value is '#{value}'" do
          subject.admin = value
          expect(subject.admin).to eq(false)
        end
      end

      ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.each do |value|
        it "coerces the value to true when the value is '#{value}'" do
          subject.admin = value
          expect(subject.admin).to eq(true)
        end
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.admin).to eq(admin)
      end
    end

    context "date fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["approved_on"]).to eq(approved_on.to_s)
      end

      it "coerces the value" do
        subject.approved_on = approved_on.to_s
        expect(subject.approved_on).to eq(approved_on)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.approved_on).to eq(approved_on)
      end
    end

    context "datetime fields" do
      it "sets the value in the jsonb field" do
        expect(DateTime.parse(subject.options["reviewed_at"]).to_s).to eq(reviewed_at.to_s)
      end

      it "coerces the value" do
        subject.reviewed_at = reviewed_at.to_s
        expect(subject.reviewed_at).to eq(reviewed_at)
      end

      it "coerces infinity" do
        subject.reviewed_at = "infinity"
        expect(subject.reviewed_at).to eq(::Float::INFINITY)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.reviewed_at).to eq(reviewed_at)
      end
    end

    context "decimal fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["precision"]).to eq(precision.to_s)
      end

      it "coerces the value" do
        subject.precision = precision.to_s
        expect(subject.precision).to eq(precision)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.precision).to eq(precision)
      end

      it "uses the postgres decimal type" do
        expect(JsonbAccessor::Macro::ClassMethods::TYPES[:decimal]).to eq(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal)
      end
    end

    context "time fields" do
      it "sets the value in the jsonb field" do
        expect(Time.parse(subject.options["reset_at"]).to_s).to eq(reset_at.to_s)
      end

      it "coerces the value" do
        subject.reset_at = reset_at.to_s
        expect(subject.reset_at.hour).to eq(reset_at.hour)
        expect(subject.reset_at.min).to eq(reset_at.min)
        expect(subject.reset_at.sec).to eq(reset_at.sec)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.reset_at.hour).to eq(reset_at.hour)
        expect(subject.reset_at.min).to eq(reset_at.min)
        expect(subject.reset_at.sec).to eq(reset_at.sec)
      end
    end

    context "float fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["amount_floated"]).to eq(amount_floated)
      end

      it "coerces the value" do
        subject.amount_floated = amount_floated.to_s
        expect(subject.amount_floated).to eq(amount_floated)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.amount_floated).to eq(amount_floated)
      end
    end
  end

  context "dirty tracking" do
    subject { Product.new }

    ALL_FIELDS.each do |field|
      [:_before_type_cast, :_came_from_user?, :_change, :_changed?, :_was, :_will_change!].each do |method_extension|
        it "implements #{field}#{method_extension}" do
          expect(subject).to respond_to("#{field}#{method_extension}")
        end
      end
    end

    ALL_FIELDS.each do |field|
      [:reset_, :restore_].each do |method_prefix|
        method_name = "#{method_prefix}#{field}!"
        it "implements #{method_name}" do
          expect(subject).to respond_to(method_name)
        end
      end
    end
  end

  context "predicate methods" do
    subject { Product.new }

    ALL_FIELDS.each do |field|
      it "implements #{field}?" do
        expect(subject).to respond_to("#{field}?")
      end
    end
  end
end
