require "spec_helper"

RSpec.describe JsonbAccessor::ClassBuilder do
  describe "#generate_class" do
    before do
      stub_const("SomeNamespace", Module.new)
    end

    it "creates a class in the given namespace" do
      subject.generate_class(SomeNamespace, :some_attribute, foo: :string)

      expect(defined?(SomeNamespace::SomeAttribute)).to eq("constant")
      expect(SomeNamespace::SomeAttribute).to be_a(Class)
      expect(SomeNamespace::SomeAttribute.ancestors).to include(JsonbAccessor::NestedBase)
    end

    it "defines classes in the given namespace recursively" do
      subject.generate_class(SomeNamespace, :some_attribute, nested: { things: { in_here: { man: :string } } })

      expect(defined?(SomeNamespace::SomeAttribute::Nested)).to eq("constant")
      expect(SomeNamespace::SomeAttribute::Nested).to be_a(Class)
      expect(SomeNamespace::SomeAttribute::Nested.ancestors).to include(JsonbAccessor::NestedBase)

      expect(defined?(SomeNamespace::SomeAttribute::Nested::Things)).to eq("constant")
      expect(SomeNamespace::SomeAttribute::Nested::Things).to be_a(Class)
      expect(SomeNamespace::SomeAttribute::Nested::Things.ancestors).to include(JsonbAccessor::NestedBase)

      expect(defined?(SomeNamespace::SomeAttribute::Nested::Things::InHere)).to eq("constant")
      expect(SomeNamespace::SomeAttribute::Nested::Things::InHere).to be_a(Class)
      expect(SomeNamespace::SomeAttribute::Nested::Things::InHere.ancestors).to include(JsonbAccessor::NestedBase)
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
      expect(defined?(SomeNamespace::Foo)).to eq("constant")
      expect(defined?(SomeNamespace::Oof)).to eq("constant")
    end

    it "is a mapping of names to classes" do
      expect(mapping[:foo]).to eq(SomeNamespace::Foo)
      expect(mapping[:oof]).to eq(SomeNamespace::Oof)
    end

    it "is recursive" do
      expect(defined?(SomeNamespace::Foo::Bar)).to eq("constant")
      expect(defined?(SomeNamespace::Oof::Rab)).to eq("constant")
    end
  end

  context "generated classes" do
    let(:dummy_class) { SomeNamespace::SomeClass }
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
            expect(dummy.baz).to be_a(dummy_class::Baz)
          end

          it "puts the dynamic class instance's attributes into attributes" do
            expect(dummy.attributes[:baz]).to equal(dummy.baz.attributes)
          end
        end

        context "a dynamic class" do
          let(:baz) { dummy_class::Baz.new(foo: "bar") }
          before { dummy.baz = baz }

          it "sets the instance" do
            expect(dummy.baz).to eq(baz)
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
          bar: ActiveRecord::Type::Integer.new
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
        expect(dummy_class.nested_classes).to eq(baz: dummy_class::Baz)
      end
    end
  end
end
