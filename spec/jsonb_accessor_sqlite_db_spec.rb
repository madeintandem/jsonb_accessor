# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SQLite support" do
  return if ActiveRecord::VERSION::MAJOR < 6

  def build_class(jsonb_accessor_config, &block)
    Class.new(ActiveRecord::Base) do
      def self.name
        "product"
      end

      root_dir = File.expand_path(__dir__)
      establish_connection adapter: "sqlite3", database: File.join(root_dir, "..", "db", "test.db")
      connection.create_table :products, force: true do |t|
        t.json :options
        t.json :data

        t.string :string_type
        t.integer :integer_type
        t.integer :product_category_id
        t.boolean :boolean_type
        t.float :float_type
        t.time :time_type
        t.date :date_type
        t.datetime :datetime_type
        t.decimal :decimal_type
      end

      connection.create_table :product_categories, force: true do |t|
        t.json :options
      end

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
      baz: [:integer],
      bazzle: [:integer, { default: 5 }]
    )
  end
  let(:instance) { klass.new }

  it "has a version number" do
    expect(JsonbAccessor::VERSION).to_not be nil
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

    it "supports defaults" do
      expect(instance.bazzle).to eq(5)
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
          attribute :options, :json, default: {}
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
    let(:klass) do
      build_class(foo: :datetime)
    end
    let(:time_with_zone) do
      Time.new(2022, 1, 1, 12, 5, 0, "-03:00")
    end
    it "saves in UTC" do
      instance.foo = time_with_zone
      expect(instance.options).to eq({ "foo" => "2022-01-01 15:05:00.000" })
    end

    context "when default_timezone is local" do
      around(:each) do |example|
        active_record_base = if ActiveRecord.respond_to? :default_timezone
                               ActiveRecord
                             else
                               ActiveRecord::Base
                             end
        active_record_base.default_timezone = :local
        example.run
        active_record_base.default_timezone = :utc
      end
      it "saves in local time" do
        instance.foo = time_with_zone
        expect(instance.options).to eq({ "foo" => "2022-01-01 12:05:00.000" })
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

  # JSON queries
  describe "#jsonb_contains" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: title) }
    let!(:other_matching_record) { Product.create!(title: title) }
    let!(:ignored_record) { Product.create!(title: "ignored") }
    subject { Product.all }

    it "is a collection of records that match the query" do
      query = subject.jsonb_contains(:options, title: title)
      expect(query).to exist
      expect(query).to match_array([matching_record, other_matching_record])
    end

    it "escapes sql" do
      expect do
        subject.jsonb_contains(:options, title: "foo\"};delete from products where id = #{matching_record.id}").to_a
      end.to_not raise_error
      expect(subject.count).to eq(3)
    end

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_contains(:nope, title: "foo")
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidColumnName)
      end
    end

    context "table names" do
      let!(:product_category) { ProductCategory.create!(title: "category") }

      before do
        product_category.products << matching_record
        product_category.products << other_matching_record
      end

      it "is not ambigious which table is being referenced" do
        expect do
          subject.joins(:product_category).merge(ProductCategory.jsonb_contains(:options, title: "category")).to_a
        end.to_not raise_error
      end
    end
  end

  describe "#jsonb_excludes" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: title) }
    let!(:other_matching_record) { Product.create!(title: title) }
    let!(:ignored_record) { Product.create!(title: "ignored") }

    subject { Product.all }

    it "is a collection of records that don't match the query" do
      query = subject.jsonb_excludes(:options, title: ignored_record.title)
      expect(query).to exist
      expect(query).to match_array([matching_record, other_matching_record])
    end

    it "escapes sql" do
      expect do
        subject.jsonb_excludes(:options, title: "foo\"};delete from products where id = #{matching_record.id}").to_a
      end.to_not raise_error
      expect(subject.count).to eq(3)
    end

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_excludes(:nope, title: "foo")
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidColumnName)
      end
    end

    context "table names" do
      let!(:product_category) { ProductCategory.create!(title: "category") }

      before do
        product_category.products << matching_record
        product_category.products << other_matching_record
      end

      it "is not ambigious which table is being referenced" do
        expect do
          subject.joins(:product_category).merge(ProductCategory.jsonb_excludes(:options, title: "category")).to_a
        end.to_not raise_error
      end
    end
  end

  describe "#jsonb_number_where" do
    let!(:high_rank_record) { Product.create!(rank: 5) }
    let!(:middle_rank_record) { Product.create!(rank: 4) }
    let!(:low_rank_record) { Product.create!(rank: 0) }
    subject { Product.all }

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_number_where(:nope, :rank, ">", middle_rank_record.rank)
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidColumnName)
      end
    end

    context "greater than" do
      it "is matching records" do
        [:>, :greater_than, :gt, ">", "greater_than", "gt"].each do |operator|
          query = subject.jsonb_number_where(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to eq([high_rank_record])
        end
      end
    end

    context "less than" do
      it "is matching records" do
        [:<, :less_than, :lt, "<", "less_than", "lt"].each do |operator|
          query = subject.jsonb_number_where(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to eq([low_rank_record])
        end
      end
    end

    context "less than or equal to" do
      it "is matching records" do
        [:<=, :less_than_or_equal_to, :lte, "<=", "less_than_or_equal_to", "lte"].each do |operator|
          query = subject.jsonb_number_where(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([low_rank_record, middle_rank_record])
        end
      end
    end

    context "greater than or equal to" do
      it "is matching records" do
        [:>=, :greater_than_or_equal_to, :gte, ">=", "greater_than_or_equal_to", "gte"].each do |operator|
          query = subject.jsonb_number_where(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([high_rank_record, middle_rank_record])
        end
      end
    end
  end

  describe "#jsonb_number_where_not" do
    let!(:high_rank_record) { Product.create!(rank: 5) }
    let!(:middle_rank_record) { Product.create!(rank: 4) }
    let!(:low_rank_record) { Product.create!(rank: 0) }
    subject { Product.all }

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_number_where_not(:nope, :rank, ">", middle_rank_record.rank)
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidColumnName)
      end
    end

    context "greater than" do
      it "excludes matching records" do
        [:>, :greater_than, :gt, ">", "greater_than", "gt"].each do |operator|
          query = subject.jsonb_number_where_not(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([low_rank_record, middle_rank_record])
        end
      end
    end

    context "less than" do
      it "excludes matching records" do
        [:<, :less_than, :lt, "<", "less_than", "lt"].each do |operator|
          query = subject.jsonb_number_where_not(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([high_rank_record, middle_rank_record])
        end
      end
    end

    context "less than or equal to" do
      it "excludes matching records" do
        [:<=, :less_than_or_equal_to, :lte, "<=", "less_than_or_equal_to", "lte"].each do |operator|
          query = subject.jsonb_number_where_not(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([high_rank_record])
        end
      end
    end

    context "greater than or equal to" do
      it "excludes matching records" do
        [:>=, :greater_than_or_equal_to, :gte, ">=", "greater_than_or_equal_to", "gte"].each do |operator|
          query = subject.jsonb_number_where_not(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([low_rank_record])
        end
      end
    end
  end

  describe "#jsonb_time_where" do
    let!(:early_record) { Product.create!(made_at: 10.days.ago) }
    let!(:late_record) { Product.create!(made_at: 2.days.from_now) }
    subject { Product.all }

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_time_where(:nope, :made_at, "before", Time.current)
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidColumnName)
      end
    end

    context "before" do
      it "is matching records" do
        [:before, "before"].each do |operator|
          query = subject.jsonb_time_where(:options, :made_at, operator, Time.current)
          expect(query).to exist
          expect(query).to eq([early_record])
        end
      end
    end

    context "after" do
      it "is matching records" do
        [:after, "after"].each do |operator|
          query = subject.jsonb_time_where(:options, :made_at, operator, Time.current)
          expect(query).to exist
          expect(query).to eq([late_record])
        end
      end
    end
  end

  describe "#jsonb_time_where_not" do
    let!(:early_record) { Product.create!(made_at: 10.days.ago) }
    let!(:late_record) { Product.create!(made_at: 2.days.from_now) }
    subject { Product.all }

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_time_where_not(:nope, :made_at, "before", Time.current)
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidColumnName)
      end
    end

    context "before" do
      it "excludes matching records" do
        [:before, "before"].each do |operator|
          query = subject.jsonb_time_where_not(:options, :made_at, operator, Time.current)
          expect(query).to exist
          expect(query).to eq([late_record])
        end
      end
    end

    context "after" do
      it "excludes matching records" do
        [:after, "after"].each do |operator|
          query = subject.jsonb_time_where_not(:options, :made_at, operator, Time.current)
          expect(query).to exist
          expect(query).to eq([early_record])
        end
      end
    end
  end

  describe "#jsonb_where" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: title, rank: 4, made_at: Time.current) }
    let!(:ignored_record) { Product.create!(title: "ignored", rank: 8, made_at: 3.years.ago) }
    let!(:blank_record) { Product.create! }
    subject { Product.all }

    context "contains" do
      it "is matching records" do
        query = subject.jsonb_where(:options, title: title)
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "number queries" do
      it "is records matching the criteria" do
        query = subject.jsonb_where(:options, rank: { greater_than: 3, less_than: 7 })
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "time queries" do
      it "is records matching the criteria" do
        query = subject.jsonb_where(:options, made_at: { before: 2.days.from_now, after: 2.days.ago })
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "number ranges" do
      it "is records within the range" do
        query = subject.jsonb_where(:options, rank: 3...6)
        expect(query).to exist
        expect(query).to eq([matching_record])
      end

      context "excluding the end" do
        it "is the records within the range" do
          query = subject.jsonb_where(:options, rank: 3...8)
          expect(query).to exist
          expect(query).to eq([matching_record])
        end
      end

      context "including the end" do
        it "is the records within the range" do
          query = subject.jsonb_where(:options, rank: 1..4)
          expect(query).to exist
          expect(query).to eq([matching_record])
        end
      end
    end

    context "time ranges" do
      it "is records within the range" do
        query = subject.jsonb_where(:options, made_at: 2.days.ago..2.days.from_now)
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "smoke test" do
      it "is records matching the criteria" do
        query = subject.jsonb_where(
          :options,
          title: title,
          rank: { greater_than: 3, less_than: 7 },
          made_at: { before: 2.days.from_now, after: 2.days.ago }
        )
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end
  end

  describe "#jsonb_where_not" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: "not excluded", rank: 3, made_at: 3.years.ago) }
    let!(:ignored_record) { Product.create!(title: title, rank: 5, made_at: Time.current) }
    let!(:blank_record) { Product.create! }
    subject { Product.all }

    context "contains" do
      it "excludes matching records" do
        query = subject.jsonb_where_not(:options, title: ignored_record.title)
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "number queries" do
      it "excludes records matching the criteria" do
        query = subject.jsonb_where_not(:options, rank: { greater_than: 3 })
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "time queries" do
      it "excludes records matching the criteria" do
        query = subject.jsonb_where_not(:options, made_at: { after: 2.days.ago })
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "ranges" do
      it "raises an error when any value is a range" do
        expect { subject.jsonb_where_not(:options, rank: 4...6) }.to raise_error(JsonbAccessor::QueryHelper::NotSupported, "`jsonb_where_not` scope does not accept ranges as arguments. Given `4...6` for `rank` field")
      end
    end

    context "smoke test" do
      it "excludes records matching the criteria" do
        query = subject.jsonb_where_not(
          :options,
          title: title,
          rank: { greater_than: 3 },
          made_at: { after: 2.days.ago }
        )
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end
  end
  describe "#jsonb_order" do
    let!(:second_product) { Product.create!(title: "B") }
    let!(:last_product) { Product.create!(title: "C") }
    let!(:first_product) { Product.create!(title: "A") }
    let(:ordered_records) { [first_product, second_product, last_product] }
    subject { Product.all }

    it "orders by the given attribute and direction" do
      expect(subject.jsonb_order(:options, :title, :asc)).to eq(ordered_records)
      expect(subject.jsonb_order(:options, :title, :desc)).to eq(ordered_records.reverse)
    end

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_order(:nah, :title, :asc)
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidColumnName)
      end
    end

    context "given an invalid field" do
      it "raises an error" do
        expect do
          subject.jsonb_order(:options, :nah, :asc)
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidFieldName)
      end
    end

    context "given an invalid direction" do
      it "raises an error" do
        expect do
          subject.jsonb_order(:options, :title, :nah)
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidDirection)
      end
    end
  end
end
