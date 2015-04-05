require "spec_helper"

RSpec.describe JsonbAccessor::TypeHelper do
  describe "#fetch" do
    context "recognizes type" do
      it "is the type" do
        expect(subject.fetch(:string)).to eq(ActiveRecord::Type::String.new)
      end
    end

    context "does not recognize type" do
      it "is a value type" do
        expect(subject.fetch(:not_a_type)).to eq(ActiveRecord::Type::Value.new)
      end
    end
  end
end
