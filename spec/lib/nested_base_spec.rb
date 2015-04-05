require "spec_helper"

RSpec.describe JsonbAccessor::NestedBase do
  context "attr_accessor" do
    it { is_expected.to attr_accessorize(:parent) }
    it { is_expected.to attr_accessorize(:attributes) }
  end

  context "delegation" do
    it { is_expected.to delegate_method(:[]).to(:attributes) }
    it { is_expected.to delegate_method(:nested_classes).to(:class) }
  end

  context "aliases" do
    it { is_expected.to alias_the_method(:attributes).to(:to_h) }
  end

  describe "#initialize" do
    context "sets" do
      let(:attributes) { { foo: 5, bar: "baz" } }
      let(:dummy_class) do
        Class.new(JsonbAccessor::NestedBase) do
          def foo=(value)
          end

          def bar=(value)
          end
        end
      end
      subject { dummy_class.new(attributes) }

      it "attributes via the setters" do
        expect_any_instance_of(dummy_class).to receive(:foo=)
        expect_any_instance_of(dummy_class).to receive(:bar=)
        expect(subject.attributes).to be_a(ActiveSupport::HashWithIndifferentAccess)
      end
    end

    context "defaults" do
      subject { JsonbAccessor::NestedBase.new }

      it "attributes to an empty hash" do
        expect(subject.attributes).to eq({})
        expect(subject.attributes).to be_a(ActiveSupport::HashWithIndifferentAccess)
      end
    end
  end

  describe "#[]=" do
    let(:dummy_class) do
      Class.new(JsonbAccessor::NestedBase) do
        def foo=(value)
        end
      end
    end
    subject { dummy_class.new }

    it "uses the setter method" do
      expect(subject).to receive(:foo=).with(5)
      subject[:foo] = 5
    end
  end
end
