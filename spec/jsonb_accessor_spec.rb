# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonbAccessor do
  def build_class(jsonb_accessor_config, &block)
    Class.new(ActiveRecord::Base) do
      self.table_name = "products"
      jsonb_accessor :options, jsonb_accessor_config
      instance_eval(&block) if block

      attribute :bang, :string
    end
  end

  let(:klass) do
    build_class(
      foo: :string,
      bar: :integer,
      ban: :integer,
      baz: [:integer, { array: true }],
      bazzle: [:integer, { default: 5 }],
      dates: [:datetime, { array: true }]
    ) do
      enum ban: { foo: 1, bar: 2 } if JsonbAccessor.enum_support?
    end
  end
  let(:instance) { klass.new }

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
    it "defines getters and setters for the given methods" do
      expect(instance).to attr_accessorize(:foo)
      expect(instance).to attr_accessorize(:bar)
      expect(instance).to attr_accessorize(:baz)
    end

    it "supports types" do
      instance.foo = 12
      expect(instance.foo).to eq("12")

      instance.bar = "12"
      expect(instance.bar).to eq(12)
    end

    it "supports arrays" do
      instance.baz = %w[1 2 3]
      expect(instance.baz).to eq([1, 2, 3])
    end

    it "supports array of date" do
      # Write
      instance.dates = [Date.new(2017, 1, 1), Date.new(2017, 1, 2)]
      expect { instance.save! }.to_not raise_error
      # Read
      instance.reload

      expect(instance.dates).to be_kind_of Array
      expect(instance.dates.first).to be_kind_of Time
    end

    it "supports defaults" do
      expect(instance.bazzle).to eq(5)
    end

    if JsonbAccessor.enum_support?
      it "supports enums" do
        instance.ban = :foo
        expect(instance.ban).to eq("foo")
        expect(instance.options["ban"]).to eq(1)
      end
    end

    it "initializes without the jsonb_accessor field selected" do
      instance.save!

      expect do
        Product.select(:id).first
      end.not_to raise_error
    end
  end

  context "getters" do
    let(:klass) do
      build_class(foo: :string) do
        define_method(:foo) { super().upcase }
      end
    end

    it "is overridable" do
      instance.foo = "foo"
      expect(instance.foo).to eq("FOO")
      expect(instance.options).to eq("foo" => "FOO")
    end
  end

  context "setters" do
    let(:klass) do
      build_class(foo: :string, bar: :integer) do
        define_method(:foo=) { |value| super(value.downcase) }
      end
    end

    it "updates the jsonb column" do
      foo = "foo"
      instance.foo = foo
      expect(instance.options).to eq("foo" => foo)

      bar = 17
      instance.bar = bar
      expect(instance.options).to eq("foo" => foo, "bar" => bar)
    end

    it "is overridable" do
      instance.foo = "FOO"
      expect(instance.foo).to eq("foo")
      expect(instance.options).to eq("foo" => "foo")
    end
  end

  context "defaults" do
    let(:klass) do
      counter = 0
      build_class(foo: [:string, { default: "bar" }], baz: [:integer, { default: -> { counter += 1 } }])
    end

    it "allows defaults (literal and as proc)" do
      expect(instance.foo).to eq("bar")
      expect(instance.baz).to eq(1)
      expect(instance.options).to eq("foo" => "bar", "baz" => 1)

      # Make sure the default proc is evaluated each time an instance is created
      expect(klass.new.baz).to eq(2)
    end

    context "false as a default" do
      let(:klass) do
        build_class(foo: [:boolean, { default: false }])
      end

      it "allows false" do
        expect(instance.foo).to eq(false)
        expect(instance.options).to eq("foo" => false)
      end
    end

    context "inheritance" do
      let(:subklass) do
        counter = 100
        Class.new(klass) do
          jsonb_accessor :options, bazbaz: [:integer, { default: -> { counter += 1 } }]
        end
      end

      it "allows procs as default values in both superclasses and subclasses" do
        instance = subklass.new
        expect(instance.baz).to eq(1)
        expect(instance.bazbaz).to eq(101)

        instance = subklass.new
        expect(instance.baz).to eq(2)
        expect(instance.bazbaz).to eq(102)
      end
    end

    context "store keys" do
      let(:klass) do
        build_class(foo: [:string, { default: "bar", store_key: :f }])
      end

      it "puts the default value in the jsonb hash at the given store key" do
        expect(instance.foo).to eq("bar")
        expect(instance.options).to eq("f" => "bar")
      end

      context "inheritance" do
        let(:subklass) do
          Class.new(klass) do
            jsonb_accessor :options, bar: [:integer, { default: 2, store_key: :o }]
          end
        end
        let(:subklass_instance) { subklass.new }

        it "includes default values from the parent in the jsonb hash with the correct store keys" do
          expect(subklass_instance.foo).to eq("bar")
          expect(subklass_instance.bar).to eq(2)
          expect(subklass_instance.options).to eq("f" => "bar", "o" => 2)
        end
      end
    end

    context "dirty tracking" do
      let(:default_class) do
        Class.new(ActiveRecord::Base) do
          self.table_name = "products"
          attribute :options, :jsonb, default: {}
        end
      end
      let(:default_instance) { default_class.new }

      it "is dirty the same way that overriding the default for a column via `attribute` dirties the model" do
        expect(instance).to be_options_changed
        expect(default_instance).to be_options_changed
        instance.save!
        default_instance.save!
        expect(instance).to_not be_options_changed
        expect(default_instance).to_not be_options_changed
        expect(instance.class.find(instance.id)).to_not be_options_changed
        expect(default_instance.class.find(default_instance.id)).to_not be_options_changed
      end
    end
  end

  context "setting the jsonb field directly" do
    let(:klass) do
      build_class(foo: :string, bar: :integer, baz: [:string, { store_key: :b }])
    end

    let(:subklass) do
      Class.new(klass) do
        jsonb_accessor :options, sub: [:integer, { store_key: :s }]
      end
    end

    let(:subklass_instance) { subklass.new }

    before do
      instance.foo = "foo"
      instance.bar = 12
      subklass_instance.foo = "foo"
      subklass_instance.bar = 12
      subklass_instance.sub = 4
    end

    it "sets the jsonb field" do
      new_value = { "foo" => "bar" }
      instance.options = new_value
      subklass_instance.options = new_value
      expect(instance.options).to eq("foo" => "bar")
      expect(subklass_instance.options).to eq("foo" => "bar")
    end

    it "clears the fields that are not set" do
      new_value = { foo: "new foo" }
      instance.options = new_value
      subklass_instance.options = new_value
      expect(instance.bar).to be_nil
      expect(subklass_instance.bar).to be_nil
    end

    it "sets the fields given in object" do
      new_value = { foo: "new foo" }
      instance.options = new_value
      subklass_instance.options = new_value
      expect(instance.foo).to eq("new foo")
      expect(subklass_instance.foo).to eq("new foo")
      expect(instance.options).to eq new_value.stringify_keys
      expect(subklass_instance.options).to eq new_value.stringify_keys
    end

    it "stores the data using store keys" do
      new_value = { baz: "baz" }
      instance.options = new_value
      subklass_instance.options = new_value
      expect(instance.options).to eq({ "b" => "baz" })
      expect(subklass_instance.options).to eq({ "b" => "baz" })
    end

    it "it allows store keys to be used" do
      new_value = { "b" => "b" }
      instance.options = new_value
      subklass_instance.options = new_value.merge(s: 22)
      expect(instance.baz).to eq "b"
      expect(subklass_instance.baz).to eq "b"
      expect(subklass_instance.sub).to eq 22
      expect(instance.options).to eq new_value
      expect(subklass_instance.options).to eq new_value.merge("s" => 22)
    end

    context "when nil" do
      it "clears all fields" do
        instance.options = nil
        subklass_instance.options = nil
        expect(instance.foo).to be_nil
        expect(instance.bar).to be_nil
        expect(subklass_instance.foo).to be_nil
        expect(subklass_instance.bar).to be_nil
        expect(subklass_instance.sub).to be_nil
      end
    end

    it "does not write a normal Ruby attribute" do
      expect(instance.bang).to be_nil
      instance.options = { bang: "bang" }
      expect(instance.bang).to be_nil
    end
  end

  context "dirty tracking for already persisted models" do
    let(:klass) do
      build_class(foo: :string, bar: [:string, { store_key: :b }])
    end

    it "is not dirty by default" do
      instance.foo = "foo"
      instance.bar = "bar"
      instance.save!
      persisted_instance = klass.find(instance.id)
      expect(persisted_instance.foo).to eq("foo")
      expect(persisted_instance.bar).to eq("bar")
      expect(persisted_instance).to_not be_foo_changed
      expect(persisted_instance).to_not be_bar_changed
      expect(persisted_instance).to_not be_options_changed
      expect(persisted_instance.changes).to be_empty

      persisted_instance = klass.find(klass.create!(foo: "foo", bar: "bar").id)
      expect(persisted_instance.foo).to eq("foo")
      expect(persisted_instance.bar).to eq("bar")
      expect(persisted_instance).to_not be_foo_changed
      expect(persisted_instance).to_not be_bar_changed
      expect(persisted_instance).to_not be_options_changed
    end
  end

  context "dirty tracking for new records" do
    let(:klass) do
      build_class(foo: :string, bar: [:string, { store_key: :b }])
    end

    it "is not dirty by default" do
      expect(instance).to_not be_options_changed
      expect(instance).to_not be_foo_changed
      expect(instance).to_not be_bar_changed

      expect(klass.new(options: {})).to_not be_foo_changed
    end
  end

  context "prefixes" do
    let(:klass) do
      build_class(foo: [:string, { default: "bar", prefix: :a }])
    end

    it "creates accessor attribute with the given prefix" do
      expect(instance.a_foo).to eq("bar")
      expect(instance.options).to eq("foo" => "bar")
    end

    context "when prefix is true" do
      let(:klass) do
        build_class(foo: [:string, { default: "bar", prefix: true }])
      end

      it "creates accessor attribute with the json_attribute name" do
        expect(instance.options_foo).to eq("bar")
        expect(instance.options).to eq("foo" => "bar")
      end
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          jsonb_accessor :options, bar: [:integer, { default: 2 }]
        end
      end
      let(:subklass_instance) { subklass.new }

      it "includes default values from the parent in the jsonb hash" do
        expect(subklass_instance.a_foo).to eq("bar")
        expect(subklass_instance.bar).to eq(2)
        expect(subklass_instance.options).to eq("foo" => "bar", "bar" => 2)
      end
    end

    context "inheritance with prefix" do
      let(:subklass) do
        Class.new(klass) do
          jsonb_accessor :options, bar: [:integer, { default: 2, prefix: :b }]
        end
      end

      let(:subklass_instance) { subklass.new }

      it "includes default values from the parent in the jsonb hash" do
        expect(subklass_instance.a_foo).to eq("bar")
        expect(subklass_instance.b_bar).to eq(2)
        expect(subklass_instance.options).to eq("foo" => "bar", "bar" => 2)
      end
    end

    context "with store keys" do
      let(:klass) do
        build_class(foo: [:string, { default: "bar", store_key: :g, prefix: :a }])
      end

      it "creates accessor attribute with the given prefix and with the given store key" do
        expect(instance.a_foo).to eq("bar")
        expect(instance.options).to eq("g" => "bar")
      end

      context "inheritance" do
        let(:subklass) do
          Class.new(klass) do
            jsonb_accessor :options, bar: [:integer, { default: 2, store_key: :h }]
          end
        end
        let(:subklass_instance) { subklass.new }

        it "includes default values from the parent in the jsonb hash with the correct store keys" do
          expect(subklass_instance.a_foo).to eq("bar")
          expect(subklass_instance.bar).to eq(2)
          expect(subklass_instance.options).to eq("g" => "bar", "h" => 2)
        end
      end

      context "inheritance with prefix" do
        let(:subklass) do
          Class.new(klass) do
            jsonb_accessor :options, bar: [:integer, { default: 2, store_key: :i, prefix: :b }]
          end
        end
        let(:subklass_instance) { subklass.new }

        it "includes default values from the parent in the jsonb hash with the correct store keys" do
          expect(subklass_instance.a_foo).to eq("bar")
          expect(subklass_instance.b_bar).to eq(2)
          expect(subklass_instance.options).to eq("g" => "bar", "i" => 2)
        end
      end
    end
  end

  context "suffixes" do
    let(:klass) do
      build_class(foo: [:string, { default: "bar", suffix: :a }])
    end

    it "creates accessor attribute with the given suffix" do
      expect(instance.foo_a).to eq("bar")
      expect(instance.options).to eq("foo" => "bar")
    end

    context "when suffix is true" do
      let(:klass) do
        build_class(foo: [:string, { default: "bar", suffix: true }])
      end

      it "creates accessor attribute with the json_attribute name" do
        expect(instance.foo_options).to eq("bar")
        expect(instance.options).to eq("foo" => "bar")
      end
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          jsonb_accessor :options, bar: [:integer, { default: 2 }]
        end
      end
      let(:subklass_instance) { subklass.new }

      it "includes default values from the parent in the jsonb hash" do
        expect(subklass_instance.foo_a).to eq("bar")
        expect(subklass_instance.bar).to eq(2)
        expect(subklass_instance.options).to eq("foo" => "bar", "bar" => 2)
      end
    end

    context "inheritance with suffix" do
      let(:subklass) do
        Class.new(klass) do
          jsonb_accessor :options, bar: [:integer, { default: 2, suffix: :b }]
        end
      end

      let(:subklass_instance) { subklass.new }

      it "includes default values from the parent in the jsonb hash" do
        expect(subklass_instance.foo_a).to eq("bar")
        expect(subklass_instance.bar_b).to eq(2)
        expect(subklass_instance.options).to eq("foo" => "bar", "bar" => 2)
      end
    end

    context "with store keys" do
      let(:klass) do
        build_class(foo: [:string, { default: "bar", store_key: :g, suffix: :a }])
      end

      it "creates accessor attribute with the given suffix and with the given store key" do
        expect(instance.foo_a).to eq("bar")
        expect(instance.options).to eq("g" => "bar")
      end

      context "inheritance" do
        let(:subklass) do
          Class.new(klass) do
            jsonb_accessor :options, bar: [:integer, { default: 2, store_key: :h }]
          end
        end
        let(:subklass_instance) { subklass.new }

        it "includes default values from the parent in the jsonb hash with the correct store keys" do
          expect(subklass_instance.foo_a).to eq("bar")
          expect(subklass_instance.bar).to eq(2)
          expect(subklass_instance.options).to eq("g" => "bar", "h" => 2)
        end
      end

      context "inheritance with suffix" do
        let(:subklass) do
          Class.new(klass) do
            jsonb_accessor :options, bar: [:integer, { default: 2, store_key: :i, suffix: :b }]
          end
        end
        let(:subklass_instance) { subklass.new }

        it "includes default values from the parent in the jsonb hash with the correct store keys" do
          expect(subklass_instance.foo_a).to eq("bar")
          expect(subklass_instance.bar_b).to eq(2)
          expect(subklass_instance.options).to eq("g" => "bar", "i" => 2)
        end
      end
    end
  end

  describe "#<jsonb_attribute>_where" do
    let(:klass) do
      build_class(
        title: [:string, { store_key: :t }],
        rank: [:integer, { store_key: :r }],
        made_at: [:datetime, { store_key: :ma }]
      )
    end
    let(:title) { "title" }
    let!(:matching_record) { klass.create!(title: title, rank: 4, made_at: Time.current) }
    let!(:ignored_record) { klass.create!(title: "ignored", rank: 3, made_at: 3.years.ago) }
    let!(:blank_record) { klass.create! }
    subject { klass.all }

    it "is records matching the criteria" do
      query = subject.options_where(
        title: title,
        rank: { greater_than: 3, less_than: 7 },
        made_at: { before: 2.days.from_now, after: 2.days.ago }
      )
      expect(query).to exist
      expect(query).to eq([matching_record])
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          jsonb_accessor :options, other_title: [:string, { store_key: :ot }]
        end
      end
      subject { subklass.all }

      it "is records matching the criteria on a subclass" do
        query = subject.options_where(
          title: title,
          rank: { greater_than: 3, less_than: 7 },
          made_at: { before: 2.days.from_now, after: 2.days.ago }
        )
        expect(query).to exist
        expect(query.pluck(:id)).to eq([matching_record.id])
      end
    end
  end

  describe "#<jsonb_attribute>_where_not" do
    let(:klass) do
      build_class(
        title: [:string, { store_key: :t }],
        rank: [:integer, { store_key: :r }],
        made_at: [:datetime, { store_key: :ma }]
      )
    end
    let(:title) { "title" }
    let!(:matching_record) { klass.create!(title: "foo", rank: 4, made_at: Time.current) }
    let!(:ignored_record) { klass.create!(title: title, rank: 3, made_at: 3.years.ago) }
    let!(:blank_record) { klass.create! }
    subject { klass.all }

    it "excludes records matching the criteria" do
      query = subject.options_where_not(
        title: title,
        rank: { greater_than: 5 },
        made_at: { before: 1.year.ago }
      )
      expect(query).to exist
      expect(query).to eq([matching_record])
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          self.table_name = "products"
          jsonb_accessor :options, other_title: [:string, { store_key: :ot }]
        end
      end
      subject { subklass.all }

      it "excludes records matching the criteria on a subclass" do
        query = subject.options_where_not(
          title: title,
          rank: { greater_than: 5 },
          made_at: { before: 1.year.ago }
        )
        expect(query).to exist
        expect(query.pluck(:id)).to eq([matching_record.id])
      end
    end
  end

  describe "#<jsonb_attribute_order>" do
    context "field name only" do
      let(:klass) { build_class(title: :string) }
      let!(:instance_1) { klass.create!(title: "B") }
      let!(:instance_2) { klass.create!(title: "C") }
      let!(:instance_3) { klass.create!(title: "A") }
      let(:ordered_intances) { [instance_3, instance_1, instance_2] }

      it "orders the values" do
        expect(klass.all.options_order(:title)).to eq(ordered_intances)
      end
    end

    context "hash argument" do
      let(:klass) { build_class(title: :string) }
      let!(:instance_1) { klass.create!(title: "B") }
      let!(:instance_2) { klass.create!(title: "C") }
      let!(:instance_3) { klass.create!(title: "A") }
      let(:ordered_intances) { [instance_2, instance_1, instance_3] }

      it "orders the values" do
        expect(klass.all.options_order(title: :desc)).to eq(ordered_intances)
      end
    end

    context "field names and a hash argument" do
      let(:klass) { build_class(title: :string, rank: :integer, name: :string) }
      let!(:instance_1) { klass.create!(title: "B", rank: 99, name: "A") }
      let!(:instance_2) { klass.create!(title: "A", rank: 100, name: "A") }
      let!(:instance_3) { klass.create!(title: "B", rank: 99, name: "B") }
      let!(:instance_4) { klass.create!(title: "B", rank: 100, name: "A") }
      let(:ordered_intances) { [instance_2, instance_4, instance_1, instance_3] }
      let(:filtered_and_ordered_intances) { [instance_2, instance_4, instance_1] }

      it "orders the values" do
        expect(klass.all.options_order(:title, rank: :desc, name: :asc)).to eq(ordered_intances)
        expect(klass.all.options_where(name: "A").options_order(:title, rank: :desc, name: :asc)).to eq(filtered_and_ordered_intances)
      end
    end

    context "store keys" do
      let(:klass) { build_class(title: [:string, { store_key: :t }]) }
      let!(:instance_1) { klass.create!(title: "B") }
      let!(:instance_2) { klass.create!(title: "C") }
      let!(:instance_3) { klass.create!(title: "A") }
      let(:ordered_intances) { [instance_3, instance_1, instance_2] }

      it "orders the values while accounting for store keys" do
        expect(klass.all.options_order(:title)).to eq(ordered_intances)
      end
    end
  end

  describe "store keys" do
    let(:klass) { build_class(foo: [:string, { store_key: :f }]) }

    it "stores the value at the given key in the jsonb attribute" do
      instance.foo = "foo"
      expect(instance.options).to eq("f" => "foo")
    end
  end

  describe "having non jsonb accessor declared fields" do
    let!(:static_product) { StaticProduct.create!(options: { "foo" => 5 }) }
    let(:product) { Product.find(static_product.id) }

    it "does not raise an error" do
      expect { product }.to_not raise_error
      expect(product.options).to eq(static_product.options)
    end
  end

  describe "when excluding the jsonb attribute field from a call to `select`" do
    it "does not raise an error" do
      expect { Product.select(:string_type).where(nil).to_a }.to_not raise_error
    end
  end

  describe ".jsonb_store_key_mapping_for_<jsonb_attribute>" do
    let(:klass) { build_class(foo: :string, bar: [:integer, { store_key: :b }]) }

    it "is a mapping of fields to store keys" do
      expect(klass.jsonb_store_key_mapping_for_options).to eq("foo" => "foo", "bar" => "b")
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          jsonb_accessor :options, baz: [:integer, { store_key: :bz }]
        end
      end

      it "includes its parent's and its own jsonb attributes" do
        expect(subklass.jsonb_store_key_mapping_for_options).to eq("foo" => "foo", "bar" => "b", "baz" => "bz")
      end
    end
  end

  describe ".jsonb_defaults_mapping_for_<jsonb_attribute>" do
    let(:klass) { build_class(bar: [:integer, { store_key: :b, default: 2 }]) }

    it "is a mapping of store keys to defaults" do
      expect(klass.jsonb_defaults_mapping_for_options).to eq("b" => 2)
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          self.table_name = "products"
          jsonb_accessor :options, baz: [:string, { store_key: :z, default: 3 }]
        end
      end

      it "is a mapping of store keys to defaults that includes its parent's mapping" do
        expect(subklass.jsonb_defaults_mapping_for_options).to eq("b" => 2, "z" => 3)
      end
    end
  end

  describe "inheritance" do
    let(:parent_class) do
      build_class(title: :string, rank: [:integer, { store_key: :r }])
    end

    let(:child_class) do
      Class.new(parent_class) do
        jsonb_accessor :options, other_title: :string, year: [:integer, { store_key: :y }]
      end
    end

    context "initialization" do
      let(:title) { "some title" }
      let(:parent) { parent_class.new(title: title, rank: 3) }
      let(:child) { child_class.new(title: title, other_title: title, rank: 4, year: 1996) }

      it "sets the object with the proper values" do
        expect(parent.title).to eq(title)
        expect(parent.rank).to eq(3)
        expect(child.title).to eq(title)
        expect(child.other_title).to eq(title)
        expect(child.rank).to eq(4)
        expect(child.year).to eq(1996)
        parent.save!
        child.save!

        db_parent = parent_class.find(parent.id)
        db_child = child_class.find(child.id)

        expect(db_parent.title).to eq(title)
        expect(db_parent.rank).to eq(3)
        expect(db_child.title).to eq(title)
        expect(db_child.other_title).to eq(title)
        expect(db_child.rank).to eq(4)
        expect(db_child.year).to eq(1996)

        expect(db_parent.title).to eq(title)
        expect(db_parent.rank).to eq(3)
        expect(db_child.title).to eq(title)
        expect(db_child.other_title).to eq(title)
        expect(db_child.rank).to eq(4)
        expect(db_child.year).to eq(1996)
      end
    end
  end

  context "datetime field" do
    let(:klass) { build_class(foo: :datetime) }
    let(:time_with_zone) { Time.new(2022, 1, 1, 12, 5, 0, "-03:00") }
    let(:now) { Time.zone.parse("2022-09-18 09:44:00") }

    it "saves in UTC" do
      instance.foo = time_with_zone
      expect(instance.options).to eq({ "foo" => "2022-01-01 15:05:00.000" })
    end

    it "deserializes to time with zone", tz: "America/Los_Angeles" do
      travel_to now do
        # we are -7 hours from UTC
        instance = klass.new({ options: { "foo" => "2022-09-18 16:44:00" } })
        expect(instance.foo).to eq Time.new(2022, 9, 18, 9, 44, 0, "-07:00")
      end
    end

    context "when default_timezone is local", ar_default_tz: :local do
      it "saves in local time" do
        instance.foo = time_with_zone
        expect(instance.options).to eq({ "foo" => "2022-01-01 12:05:00.000" })
      end

      it "deserializes to time with zone", tz: "Europe/Berlin" do
        travel_to now do
          # we are +2 hours from UTC
          instance = klass.new({ options: { "foo" => "2022-09-18 16:44:00" } })
          expect(instance.foo).to eq Time.new(2022, 9, 18, 16, 44, 0, "+02:00")
        end
      end
    end
  end

  describe "arbitrary data" do
    let(:field) { "external" }
    let(:some_value) { ["any", "value", { "really" => "actually" }] }

    it "is possible to set arbitrary data" do
      options = instance.options.merge(field => some_value)
      instance.update!(options: options)
      expect(instance.options[field]).to eq some_value

      # make sure it doesn't get lost after normal use
      instance.foo = "fooos"
      instance.save!
      instance.reload
      expect(instance.foo).to eq "fooos"
      expect(instance.options[field]).to eq some_value
    end
  end
end
