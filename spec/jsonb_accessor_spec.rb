# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonbAccessor do
  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "products"
      jsonb_accessor :options,
        foo: :string,
        bar: :integer,
        baz: [:integer, array: true],
        bazzle: [:integer, default: 5]
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

    it "supports defaults" do
      expect(instance.bazzle).to eq(5)
    end
  end

  context "getters" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options, foo: :string
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
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options,
          foo: :string,
          bar: :integer
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
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options, foo: [:string, default: "bar"]
      end
    end

    it "allows defaults" do
      expect(instance.foo).to eq("bar")
      expect(instance.options).to eq("foo" => "bar")
    end

    context "false as a default" do
      let(:klass) do
        Class.new(ActiveRecord::Base) do
          self.table_name = "products"
          jsonb_accessor :options, foo: [:boolean, default: false]
        end
      end

      it "allows false" do
        expect(instance.foo).to eq(false)
        expect(instance.options).to eq("foo" => false)
      end
    end

    context "store keys" do
      let(:klass) do
        Class.new(ActiveRecord::Base) do
          self.table_name = "products"
          jsonb_accessor :options, foo: [:string, default: "bar", store_key: :f]
        end
      end

      it "puts the default value in the jsonb hash at the given store key" do
        expect(instance.foo).to eq("bar")
        expect(instance.options).to eq("f" => "bar")
      end

      context "inheritance" do
        let(:subklass) do
          Class.new(klass) do
            self.table_name = "products"
            jsonb_accessor :options, bar: [:integer, default: 2, store_key: :o]
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
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options,
          foo: :string,
          bar: :integer,
          baz: [:string, store_key: :b]
      end
    end

    let(:subklass) do
      Class.new(klass) do
        self.table_name = "products"
        jsonb_accessor :options, sub: [:integer, store_key: :s]
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
      expect(instance.options).to eq("foo" => "bar", "bar" => nil, "b" => nil)
      expect(subklass_instance.options).to eq("foo" => "bar", "bar" => nil, "b" => nil, "s" => nil)
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
    end

    context "when store key is specified" do
      it "maps the store key to the new value" do
        new_value = { baz: "baz" }
        instance.options = new_value
        subklass_instance.options = new_value
        expect(instance.baz).to eq("baz")
        expect(instance.options).to eq("b" => "baz", "foo" => nil, "bar" => nil)
        expect(subklass_instance.baz).to eq("baz")
        expect(subklass_instance.options).to eq("b" => "baz", "foo" => nil, "bar" => nil, "s" => nil)
      end

      it "clears the store key field" do
        new_value = { baz: "baz" }
        instance.options = new_value
        subklass_instance.options = new_value
        newer_value = { foo: "foo" }
        instance.options = newer_value
        subklass_instance.options = newer_value

        expect(instance.baz).to be_nil
        expect(instance.options).to eq("foo" => "foo", "b" => nil, "bar" => nil)
        expect(subklass_instance.baz).to be_nil
        expect(subklass_instance.options).to eq("foo" => "foo", "b" => nil, "bar" => nil, "s" => nil)
      end
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
  end

  context "dirty tracking for already persisted models" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options,
          foo: :string,
          bar: [:string, store_key: :b]
      end
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
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options,
          foo: :string,
          bar: [:string, store_key: :b]
      end
    end

    it "is not dirty by default" do
      expect(instance).to_not be_options_changed
      expect(instance).to_not be_foo_changed
      expect(instance).to_not be_bar_changed

      expect(klass.new(options: {})).to_not be_foo_changed
    end
  end

  describe "#<jsonb_attribute>_where" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options,
          title: [:string, store_key: :t],
          rank: [:integer, store_key: :r],
          made_at: [:datetime, store_key: :ma]
      end
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
          self.table_name = "products"
          jsonb_accessor :options, other_title: [:string, store_key: :ot]
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
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options,
          title: [:string, store_key: :t],
          rank: [:integer, store_key: :r],
          made_at: [:datetime, store_key: :ma]
      end
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
          jsonb_accessor :options, other_title: [:string, store_key: :ot]
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
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options, title: :string
      end
    end

    let!(:instance_1) { klass.create!(title: "B") }
    let!(:instance_2) { klass.create!(title: "C") }
    let!(:instance_3) { klass.create!(title: "A") }
    let(:ordered_intances) { [instance_3, instance_1, instance_2] }

    it "orders the values" do
      expect(klass.all.options_order(:title)).to eq(ordered_intances)
    end

    context "store keys" do
      let(:klass) do
        Class.new(ActiveRecord::Base) do
          self.table_name = "products"
          jsonb_accessor :options, title: [:string, store_key: :t]
        end
      end

      it "orders the values while accounting for store keys" do
        expect(klass.all.options_order(:title)).to eq(ordered_intances)
      end
    end
  end

  describe "store keys" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options, foo: [:string, store_key: :f]
      end
    end
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

  describe ".jsonb_store_key_mapping_for_<jsonb_attribute>" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options, foo: :string, bar: [:integer, store_key: :b]
      end
    end

    it "is a mapping of fields to store keys" do
      expect(klass.jsonb_store_key_mapping_for_options).to eq("foo" => "foo", "bar" => "b")
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          self.table_name = "products"
          jsonb_accessor :options, baz: [:integer, store_key: :bz]
        end
      end

      it "includes its parent's and its own jsonb attributes" do
        expect(subklass.jsonb_store_key_mapping_for_options).to eq("foo" => "foo", "bar" => "b", "baz" => "bz")
      end
    end
  end

  describe ".jsonb_defaults_mapping_for_<jsonb_attribute>" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options, bar: [:integer, store_key: :b, default: 2]
      end
    end

    it "is a mapping of store keys to defaults" do
      expect(klass.jsonb_defaults_mapping_for_options).to eq("b" => 2)
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          self.table_name = "products"
          jsonb_accessor :options, baz: [:string, store_key: :z, default: 3]
        end
      end

      it "is a mapping of store keys to defaults that includes its parent's mapping" do
        expect(subklass.jsonb_defaults_mapping_for_options).to eq("b" => 2, "z" => 3)
      end
    end
  end

  describe "inheritance" do
    let(:parent_class) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options, title: :string, rank: [:integer, store_key: :r]
      end
    end

    let(:child_class) do
      Class.new(parent_class) do
        self.table_name = "products"
        jsonb_accessor :options, other_title: :string, year: [:integer, store_key: :y]
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
end
