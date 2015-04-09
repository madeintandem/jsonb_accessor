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
  amount_floated: :float,
  sequential_data: :array,
  things: :json,
  stuff: :jsonb,
  a_lot_of_things: :json_array,
  a_lot_of_stuff: :jsonb_array,
  nicknames: :string_array,
  rankings: :integer_array,
  favorited_history: :boolean_array,
  login_days: :date_array,
  favorites_at: :datetime_array,
  prices: :decimal_array,
  login_times: :time_array,
  amounts_floated: :float_array,
  document: {
    nested: {
      values: :array,
      are: :string
    },
    here: :string
  }
}
ALL_FIELDS = VALUE_FIELDS + TYPED_FIELDS.keys

class Product < ActiveRecord::Base
  jsonb_accessor :options, *VALUE_FIELDS, TYPED_FIELDS
end

class OtherProduct < ActiveRecord::Base
  self.table_name = "products"
  jsonb_accessor :options, title: :string, document: { nested: { are: :string } }

  def title=(value)
    super(value.try(:upcase))
  end

  def title
    super.try(:downcase)
  end

  def reload
    super
    :wrapped
  end
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

  describe "#jsonb_accessor" do
    let!(:dummy_class) do
      klass = Class.new(ActiveRecord::Base) do
        self.table_name = "products"
      end
      stub_const("Foo", klass)
      klass.class_eval { jsonb_accessor :data, :foo }
      klass
    end

    after { JsonbAccessor }

    it "can be called twice in a class without issue" do
      expect do
        dummy_class.class_eval { jsonb_accessor :options, :bar }
      end.to_not change { JsonbAccessor::Foo }
    end
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
    let(:sequential_data) { [5, "foo", 52.8892] }
    let(:nicknames) { %w(T-Bone Crushinator) }
    let(:rankings) { [1, 4, 2, 5] }
    let(:favorited_history) { [true, false, false, true] }
    let(:login_days) { [approved_on, Date.new(2013, 2, 25)] }
    let(:favorites_at) { [reviewed_at, DateTime.new(2055, 3, 5, 6, 5, 22)] }
    let(:prices) { [precision, 123.098753] }
    let(:login_times) { [reset_at, Time.new(2005, 4, 7, 6, 1, 3)] }
    let(:amounts_floated) { [22.34, amount_floated] }
    let(:things) { { "foo" => "bar" } }
    let(:stuff) { { "bar" => "foo" } }
    let(:a_lot_of_things) { [things, stuff] }
    let(:a_lot_of_stuff) { [stuff, things] }

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
      subject.sequential_data = sequential_data
      subject.nicknames = nicknames
      subject.rankings = rankings
      subject.favorited_history = favorited_history
      subject.login_days = login_days
      subject.favorites_at = favorites_at
      subject.prices = prices
      subject.login_times = login_times
      subject.amounts_floated = amounts_floated
      subject.things = things
      subject.stuff = stuff
      subject.a_lot_of_things = a_lot_of_things
      subject.a_lot_of_stuff = a_lot_of_stuff
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
        expect(JsonbAccessor::TypeHelper.fetch(:decimal)).to be_a(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal)
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

    context "array fields" do
      context "untyped array fields" do
        it "sets the value in the jsonb field" do
          expect(subject.options["sequential_data"]).to eq(sequential_data)
        end

        it "preserves the value after a trip to the database" do
          subject.save!
          subject.reload
          expect(subject.sequential_data).to eq(sequential_data)
        end
      end

      context "typed array fields" do
        context "string typed" do
          it "sets the value in the jsonb field" do
            expect(subject.options["nicknames"]).to eq(nicknames)
          end

          it "coerces the value" do
            subject.nicknames = [5]
            expect(subject.nicknames).to eq(["5"])
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.nicknames).to eq(nicknames)
          end
        end

        context "integer typed" do
          it "sets the value in the jsonb field" do
            expect(subject.options["rankings"]).to eq(rankings)
          end

          it "coerces the value" do
            subject.rankings = %w(5)
            expect(subject.rankings).to eq([5])
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.rankings).to eq(rankings)
          end
        end

        context "boolean typed" do
          it "sets the value in the jsonb field" do
            expect(subject.options["favorited_history"]).to eq(favorited_history)
          end

          ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES.each do |value|
            it "coerces the value to false when the value is '#{value}'" do
              subject.favorited_history = [value]
              expect(subject.favorited_history).to eq([false])
            end
          end

          ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.each do |value|
            it "coerces the value to true when the value is '#{value}'" do
              subject.favorited_history = [value]
              expect(subject.favorited_history).to eq([true])
            end
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.favorited_history).to eq(favorited_history)
          end
        end

        context "date typed" do
          it "sets the value in the jsonb field" do
            expect(subject.options["login_days"]).to eq(login_days.map(&:to_s))
          end

          it "coerces the value" do
            subject.login_days = login_days.map(&:to_s)
            expect(subject.login_days).to eq(login_days)
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.login_days).to eq(login_days)
          end
        end

        context "datetime typed" do
          it "sets the value in the jsonb field" do
            jsonb_field_value = subject.options["favorites_at"].map do |value|
              DateTime.parse(value).to_s
            end
            expect(jsonb_field_value).to eq(favorites_at.map(&:to_s))
          end

          it "coerces the value" do
            subject.favorites_at = favorites_at.map(&:to_s)
            expect(subject.favorites_at).to eq(favorites_at)
          end

          it "coerces infinity" do
            subject.favorites_at = ["infinity"]
            expect(subject.favorites_at).to eq([::Float::INFINITY])
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.favorites_at).to eq(favorites_at)
          end
        end

        context "decimal typed" do
          it "sets the value in the jsonb field" do
            expect(subject.options["prices"]).to eq(prices.map(&:to_s))
          end

          it "coerces the value" do
            subject.prices = prices.map(&:to_s)
            expect(subject.prices).to eq(prices)
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.prices).to eq(prices)
          end

          it "uses the postgres decimal type" do
            subtype = JsonbAccessor::TypeHelper.fetch(:decimal_array).subtype
            expect(subtype).to be_a(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal)
          end
        end

        context "time typed" do
          it "sets the value in the jsonb field" do
            jsonb_field_value = subject.options["login_times"].map do |value|
              Time.parse(value).to_s
            end
            expect(jsonb_field_value).to eq(login_times.map(&:to_s))
          end

          it "coerces the value" do
            subject.login_times = login_times.map(&:to_s)
            expect(subject.login_times).to be_present
            subject.login_times.each_with_index do |time, i|
              expect(time.hour).to eq(login_times[i].hour)
              expect(time.min).to eq(login_times[i].min)
              expect(time.sec).to eq(login_times[i].sec)
            end
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.login_times).to be_present
            subject.login_times.each_with_index do |time, i|
              expect(time.hour).to eq(login_times[i].hour)
              expect(time.min).to eq(login_times[i].min)
              expect(time.sec).to eq(login_times[i].sec)
            end
          end
        end

        context "float typed" do
          it "sets the value in the jsonb field" do
            expect(subject.options["amounts_floated"]).to eq(amounts_floated)
          end

          it "coerces the value" do
            subject.amounts_floated = amounts_floated.map(&:to_s)
            expect(subject.amounts_floated).to eq(amounts_floated)
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.amounts_floated).to eq(amounts_floated)
          end
        end

        context "json typed" do
          it "sets the value in the jsonb field" do
            expect(subject.options["a_lot_of_things"]).to eq(a_lot_of_things)
          end

          it "coerces the value" do
            subject.a_lot_of_things = a_lot_of_things.map(&:to_json)
            expect(subject.a_lot_of_things).to eq(a_lot_of_things)
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.a_lot_of_things).to eq(a_lot_of_things)
          end
        end

        context "jsonb typed" do
          it "sets the value in the jsonb field" do
            expect(subject.options["a_lot_of_stuff"]).to eq(a_lot_of_stuff)
          end

          it "coerces the value" do
            subject.a_lot_of_stuff = a_lot_of_stuff.map(&:to_json)
            expect(subject.a_lot_of_stuff).to eq(a_lot_of_stuff)
          end

          it "preserves the value after a trip to the database" do
            subject.save!
            subject.reload
            expect(subject.a_lot_of_stuff).to eq(a_lot_of_stuff)
          end
        end
      end
    end

    context "json fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["things"]).to eq(things)
      end

      it "coerces the value" do
        subject.things = things.to_json
        expect(subject.things).to eq(things)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.things).to eq(things)
      end
    end

    context "jsonb fields" do
      it "sets the value in the jsonb field" do
        expect(subject.options["stuff"]).to eq(stuff)
      end

      it "coerces the value" do
        subject.stuff = stuff.to_json
        expect(subject.stuff).to eq(stuff)
      end

      it "preserves the value after a trip to the database" do
        subject.save!
        subject.reload
        expect(subject.stuff).to eq(stuff)
      end
    end
  end

  context "nested fields" do
    it "creates a namespace named for the class, jsonb attribute, and nested attributes" do
      expect(defined?(JsonbAccessor::Product)).to eq("constant")
      expect(defined?(JsonbAccessor::Product::Options)).to eq("constant")
      expect(defined?(JsonbAccessor::Product::Options::Document)).to eq("constant")
      expect(defined?(JsonbAccessor::Product::Options::Document::Nested)).to eq("constant")
    end

    context "getters" do
      subject { Product.new }

      before do
        subject.save!
        subject.reload
      end

      it "exists" do
        expect { subject.document.nested.are }.to_not raise_error
      end
    end

    context "setters" do
      let(:document_class) { JsonbAccessor::Product::Options::Document }
      subject { Product.new }

      it "sets itself a the object's parent" do
        expect(subject.document.parent).to eq(subject)
      end

      context "a hash" do
        before do
          subject.document = { nested: { are: "here" } }.with_indifferent_access
        end

        it "creates an instance of the correct dynamic class" do
          expect(subject.document).to be_a(document_class)
        end

        it "puts the dynamic class instance's attributes into the jsonb field" do
          expect(subject.options["document"]).to eq(subject.document.attributes)
        end
      end

      context "a dynamic class" do
        let(:document) { document_class.new(nested: nil) }
        before { subject.document = document }

        it "sets the instance" do
          expect(subject.document.attributes).to eq(document.attributes)
        end

        it "puts the dynamic class instance's attributes in the jsonb field" do
          expect(subject.options["document"]).to eq(document.attributes)
        end
      end

      context "nil" do
        before do
          subject.options["document"] = { not: :empty }
          subject.document = nil
        end

        it "sets the attribute to an empty instance of the dynamic class" do
          expect(subject.document.attributes).to eq("nested" => {})
        end

        it "clears the associated attributes in the jsonb field" do
          expect(subject.options["document"]).to eq("nested" => {})
        end
      end

      context "anything else" do
        it "raises an error" do
          expect { subject.document = 5 }.to raise_error(JsonbAccessor::UnknownValue)
        end
      end
    end
  end

  context "deeply nested setters" do
    let(:value) { "some value" }
    subject do
      Product.create!
    end

    before do
      subject.document.nested.are = value
    end

    it "changes the jsonb field" do
      expect(subject.options["document"]["nested"]["are"]).to eq(value)
    end

    it "persists after a trip to the database" do
      expect(subject.options["document"]["nested"]["are"]).to eq(value)
      subject.save!
      expect(subject.reload.options["document"]["nested"]["are"]).to eq(value)
      expect(subject.reload.document.nested.are).to eq(value)
    end
  end

  describe ".<field_name>_classes" do
    it "is a mapping of attribute names to dynamically created classes" do
      expect(Product.options_classes).to eq(document: JsonbAccessor::Product::Options::Document)
    end

    context "delegation" do
      subject { Product.new }
      it { is_expected.to delegate_method(:options_classes).to(:class) }
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

  context "overriding getters and setters" do
    subject { OtherProduct.new }

    context "setters" do
      it "can be wrapped" do
        subject.title = "Duke"
        expect(subject.options["title"]).to eq("DUKE")
      end
    end

    context "getters" do
      it "can be wrapped" do
        subject.title = "COUNT"
        expect(subject.title).to eq("count")
      end
    end
  end

  describe "#reload" do
    let(:value) { "value" }

    before do
      subject.save!
      subject.reload
      subject.document.nested.are = value
      subject.save!
    end

    context do
      subject { Product.new }

      it "works with nested attributes" do
        subject.reload
        expect(subject.document.nested.are).to eq(value)
      end

      it "is itself" do
        expect(subject.reload).to eq(subject)
      end
    end

    context "overriding" do
      subject do
        OtherProduct.new.tap do |other_product|
          other_product.save!
          other_product.reload
        end
      end

      it "can be wrapped" do
        expect(subject.reload).to eq(:wrapped)
        expect(subject.document.nested.are).to eq(value)
      end
    end
  end
end
