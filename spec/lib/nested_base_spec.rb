# # frozen_string_literal: true
# require "spec_helper"

# RSpec.describe JsonbAccessor::NestedBase do
#   let(:dummy_class) do
#     Class.new(JsonbAccessor::NestedBase) do
#       def self.nested_classes; {}; end
#     end
#   end
#   subject { dummy_class.new }

#   context "attr_accessor" do
#     it { is_expected.to attr_accessorize(:parent) }
#     it { is_expected.to attr_accessorize(:attributes) }
#   end

#   context "delegation" do
#     it { is_expected.to delegate_method(:[]).to(:attributes) }
#     it { is_expected.to delegate_method(:nested_classes).to(:class) }
#     it { is_expected.to delegate_method(:attribute_on_parent_name).to(:class) }
#   end

#   context "aliases" do
#     it { is_expected.to alias_the_method(:attributes).to(:to_h) }
#   end

#   describe "#initialize" do
#     context "sets" do
#       let(:dummy_class) do
#         Class.new(JsonbAccessor::NestedBase) do
#           def self.nested_classes
#             { foo: Class.new, bar: Class.new }
#           end

#           def foo=(value)
#           end

#           def bar=(value)
#           end
#         end
#       end

#       context "with attributes" do
#         let(:attributes) { { foo: 5, bar: "baz" } }
#         subject { dummy_class.new(attributes) }

#         it "attributes via the setters" do
#           expect_any_instance_of(dummy_class).to receive(:foo=).twice
#           expect_any_instance_of(dummy_class).to receive(:bar=).twice
#           expect(subject.attributes).to be_a(ActiveSupport::HashWithIndifferentAccess)
#         end
#       end

#       context "with nil" do
#         subject { dummy_class.new }

#         it "calls all of the nested attribute setters with nil" do
#           expect_any_instance_of(dummy_class).to receive(:foo=).with(nil)
#           expect_any_instance_of(dummy_class).to receive(:bar=).with(nil)
#           subject
#         end
#       end
#     end

#     context "defaults" do
#       it "attributes to an empty hash" do
#         expect(subject.attributes).to eq({})
#         expect(subject.attributes).to be_a(ActiveSupport::HashWithIndifferentAccess)
#       end
#     end
#   end

#   describe "#update_parent" do
#     let(:dummy_class) do
#       Class.new(JsonbAccessor::NestedBase) do
#         def self.nested_classes; {}; end

#         def self.attribute_on_parent_name; :foo; end

#         def foo=(value); end
#       end
#     end

#     context "parent" do
#       let(:parent) { dummy_class.new }
#       subject { dummy_class.new }
#       before { subject.parent = parent }

#       it "sets itself on its parent" do
#         expect(parent).to receive(:foo=).with(subject)
#         subject.update_parent
#       end
#     end

#     context "no parent" do
#       subject { dummy_class.new }
#       it "does not raise an error" do
#         expect { subject.update_parent }.to_not raise_error
#       end
#     end
#   end

#   describe "#[]=" do
#     let(:dummy_class) do
#       Class.new(JsonbAccessor::NestedBase) do
#         def self.nested_classes; {}; end

#         def foo=(value)
#         end
#       end
#     end
#     subject { dummy_class.new }

#     it "uses the setter method" do
#       expect(subject).to receive(:foo=).with(5)
#       subject[:foo] = 5
#     end
#   end

#   describe "#==" do
#     let!(:attributes) { { foo: "bar", baz: 5 } }
#     let(:dummy_class) do
#       Class.new(JsonbAccessor::NestedBase) do
#         def self.nested_classes; {}; end

#         def foo=(value)
#           attributes[:foo] = value
#         end

#         def baz=(value)
#           attributes[:baz] = value
#         end
#       end
#     end
#     subject { dummy_class.new(attributes) }

#     context "nil" do
#       it "is false" do
#         expect(subject == nil).to eq(false)
#       end
#     end

#     context "same class, same attributes" do
#       let(:suspect) { dummy_class.new(attributes) }

#       it "is true" do
#         expect(subject == suspect).to eq(true)
#       end
#     end

#     context "same class, different attributes" do
#       let!(:suspect) { dummy_class.new(foo: "bar") }

#       it "is false" do
#         expect(subject == suspect).to eq(false)
#       end
#     end

#     context "different class, same attributes" do
#       let!(:suspect) { Class.new(dummy_class).new(attributes) }

#       it "is false" do
#         expect(subject == suspect).to eq(false)
#       end
#     end
#   end
# end
