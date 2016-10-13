# frozen_string_literal: true
require "spec_helper"

RSpec.describe JsonbAccessor::ClassBuilder do
  describe "#generate_class" do
    before do
      stub_const("SomeNamespace", Module.new)
    end

    it "creates a class in the given namespace" do
      subject.generate_class(SomeNamespace, :some_attribute, foo: :string)

      expect(defined?(SomeNamespace::JASomeAttribute)).to eq("constant")
      expect(SomeNamespace::JASomeAttribute).to be_a(Class)
      expect(SomeNamespace::JASomeAttribute.ancestors).to include(JsonbAccessor::NestedBase)
    end

    it "defines classes in the given namespace recursively" do
      subject.generate_class(SomeNamespace, :some_attribute, nested: { things: { in_here: { man: :string } } })

      expect(defined?(SomeNamespace::JASomeAttribute::JANested)).to eq("constant")
      expect(SomeNamespace::JASomeAttribute::JANested).to be_a(Class)
      expect(SomeNamespace::JASomeAttribute::JANested.ancestors).to include(JsonbAccessor::NestedBase)

      expect(defined?(SomeNamespace::JASomeAttribute::JANested::JAThings)).to eq("constant")
      expect(SomeNamespace::JASomeAttribute::JANested::JAThings).to be_a(Class)
      expect(SomeNamespace::JASomeAttribute::JANested::JAThings.ancestors).to include(JsonbAccessor::NestedBase)

      expect(defined?(SomeNamespace::JASomeAttribute::JANested::JAThings::JAInHere)).to eq("constant")
      expect(SomeNamespace::JASomeAttribute::JANested::JAThings::JAInHere).to be_a(Class)
      expect(SomeNamespace::JASomeAttribute::JANested::JAThings::JAInHere.ancestors).to include(JsonbAccessor::NestedBase)
    end
  end

  describe "#generate_nested_classes" do
    before do
      stub_const("SomeNamespace", Module.new)
    end

    let!(:mapping) do
      subject.generate_nested_classes(SomeNamespace, foo: { bar: { baz: :string } }, oof: { rab: { zab: :string } })
    end

    it "creates a class for each key in the given namespace" do
      expect(defined?(SomeNamespace::JAFoo)).to eq("constant")
      expect(defined?(SomeNamespace::JAOof)).to eq("constant")
    end

    it "is a mapping of names to classes" do
      expect(mapping[:foo]).to eq(SomeNamespace::JAFoo)
      expect(mapping[:oof]).to eq(SomeNamespace::JAOof)
    end

    it "is recursive" do
      expect(defined?(SomeNamespace::JAFoo::JABar)).to eq("constant")
      expect(defined?(SomeNamespace::JAOof::JARab)).to eq("constant")
    end
  end

  describe "#generate_class_namespace" do
    context "class namespace has not been generated" do
      it "is the class namespace" do
        result = subject.generate_class_namespace("Foo")
        expect(defined?(JsonbAccessor::JAFoo)).to eq("constant")
        expect(result).to be_a(Module)
        expect(result).to eq(JsonbAccessor::JAFoo)
        JsonbAccessor.send(:remove_const, "JAFoo")
      end

      it "is the class namespace despite module nesting" do
        result = subject.generate_class_namespace("Foo::Bar")
        expect(defined?(JsonbAccessor::JAFooBar)).to eq("constant")
        expect(result).to be_a(Module)
        expect(result).to eq(JsonbAccessor::JAFooBar)
        JsonbAccessor.send(:remove_const, "JAFooBar")
      end
    end

    context "class namespace was already generated" do
      it "is the class namespace" do
        original = subject.generate_class_namespace("Foo")
        result = nil

        expect do
          result = subject.generate_class_namespace("Foo")
        end.to_not raise_error

        expect(result).to equal(original)
      end
    end
  end

  describe "#generate_attribute_namespace" do
    before { stub_const("SomeNamespace", Module.new) }

    it "is a namespace in the given class namespace" do
      result = subject.generate_attribute_namespace(:some_jsonb_attribute, SomeNamespace)
      expect(defined?(SomeNamespace::JASomeJsonbAttribute)).to eq("constant")
      expect(result).to be_a(Module)
      expect(result).to equal(SomeNamespace::JASomeJsonbAttribute)
    end
  end

  context "generated classes" do
    let(:dummy_class) { SomeNamespace::JASomeClass }
    let(:dummy) { dummy_class.new }

    before do
      stub_const("SomeNamespace", Module.new)
      subject.generate_class(SomeNamespace, :some_class, foo: :string, bar: :integer, baz: { foo: :string })
    end

    context "getters and setters" do
      it "has them" do
        dummy.foo = foo = "foo"
        dummy.bar = bar = 5

        expect(dummy.foo).to eq(foo)
        expect(dummy.bar).to eq(bar)
      end

      it "sets the value in its attributes hash" do
        dummy.foo = foo = "foo"
        dummy.baz = baz = { "foo" => "bar" }

        expect(dummy.attributes["foo"]).to eq(foo)
        expect(dummy.attributes["baz"]).to eq(baz)
      end

      it "coerces types" do
        dummy.foo = 5
        dummy.bar = "6"

        expect(dummy.foo).to eq("5")
        expect(dummy.bar).to eq(6)
      end

      it "updates its parent" do
        expect(dummy).to receive(:update_parent)
        dummy.foo = 5
      end

      context "setting nested attributes" do
        it "assigns itself as the nested attribute object's parent" do
          expect(dummy.baz.parent).to eq(dummy)
        end

        it "updates its parent" do
          expect(dummy).to receive(:update_parent)
          dummy.baz = { foo: :bar }
        end

        context "a hash" do
          before { dummy.baz = { foo: :bar }.with_indifferent_access }

          it "creates an instance of the correct dynamic class" do
            expect(dummy.baz).to be_a(dummy_class::JABaz)
          end

          it "puts the dynamic class instance's attributes into attributes" do
            expect(dummy.attributes[:baz]).to equal(dummy.baz.attributes)
          end
        end

        context "a dynamic class" do
          let(:baz) { dummy_class::JABaz.new(foo: "bar") }
          before { dummy.baz = baz }

          it "sets the instance" do
            expect(dummy.baz.attributes).to eq(baz.attributes)
          end

          it "puts the dynamic class instance's attributes in attributes" do
            expect(dummy.attributes[:baz]).to eq(baz.attributes)
          end
        end

        context "nil" do
          before do
            dummy.attributes[:baz] = { not: :empty }
            dummy.baz = nil
          end

          it "sets the attribute to an empty instance of the dynamic class" do
            expect(dummy.baz.attributes).to eq({})
          end

          it "clears the associated attributes on the parent" do
            expect(dummy.attributes[:baz]).to eq({})
          end
        end

        context "anything else" do
          it "raises an error" do
            expect { dummy.baz = 5 }.to raise_error(JsonbAccessor::UnknownValue)
          end
        end
      end
    end

    describe "#attributes_and_data_types" do
      it "is a hash of attribute names and their data types" do
        expect(dummy.attributes_and_data_types).to eq(
          foo: ActiveRecord::Type::String.new,
          bar: ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer.new
        )
      end
    end

    describe ".attribute_on_parent_name" do
      it "is the non camelized name of the class" do
        expect(dummy_class.attribute_on_parent_name).to eq(:some_class)
      end
    end

    describe ".nested_classes" do
      it "is a hash of attribute names and classes" do
        expect(dummy_class.nested_classes).to eq(baz: dummy_class::JABaz)
      end
    end
  end
end
