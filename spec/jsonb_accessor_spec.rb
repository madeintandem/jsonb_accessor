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
      instance.baz = %w(1 2 3)
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

  context "setting the jsonb field directly" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options,
          foo: :string,
          bar: :integer
      end
    end

    before do
      instance.foo = "foo"
      instance.bar = 12
    end

    it "sets the jsonb field" do
      new_value = { "foo" => "bar" }
      instance.options = new_value
      expect(instance.options).to eq(new_value)
    end

    it "clears the fields that are not set" do
      instance.options = { foo: "new foo" }
      expect(instance.bar).to be_nil
    end

    it "sets the fields given in object" do
      instance.options = { foo: "new foo" }
      expect(instance.foo).to eq("new foo")
    end

    context "when nil" do
      it "clears all fields" do
        instance.options = nil
        expect(instance.foo).to be_nil
        expect(instance.bar).to be_nil
      end
    end
  end

  context "dirty tracking for already persisted models" do
    it "is not dirty by default" do
      instance.foo = "foo"
      instance.save!
      persisted_instance = klass.find(instance.id)
      expect(persisted_instance.foo).to eq("foo")
      expect(persisted_instance).to_not be_foo_changed
      expect(persisted_instance).to_not be_options_changed

      persisted_instance = klass.find(klass.create!(foo: "foo").id)
      expect(persisted_instance.foo).to eq("foo")
      expect(persisted_instance).to_not be_foo_changed
      expect(persisted_instance).to_not be_options_changed
    end
  end

  context "dirty tracking for new records" do
    it "is not dirty by default" do
      expect(instance).to_not be_options_changed
    end
  end

  describe "#<jsonb_attribute>_where" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: title, rank: 4, made_at: Time.current) }
    let!(:ignored_record) { Product.create!(title: "ignored", rank: 3, made_at: 3.years.ago) }
    let!(:blank_record) { Product.create! }
    subject { Product.all }

    it "is records matching the criteria" do
      query = subject.options_where(
        title: title,
        rank: { greater_than: 3, less_than: 7 },
        made_at: { before: 2.days.from_now, after: 2.days.ago }
      )
      expect(query).to exist
      expect(query).to eq([matching_record])
    end
  end
end
