require "spec_helper"

class Product < ActiveRecord::Base
  jsonb_accessor :options, :name, :color
end

RSpec.describe JsonbAccessor do
  it "has a version number" do
    expect(JsonbAccessor::VERSION).to_not be nil
  end

  it "is mixed into ActiveRecord::Base" do
    expect(ActiveRecord::Base.ancestors).to include(subject)
  end

  it "defines jsonb_accessor" do
    expect(Product).to respond_to(:jsonb_accessor)
  end

  context "getters" do
    subject { Product.new }

    context "string fields" do
      it "is the value in the jsonb field" do
        name = "Marty McFly"
        color = "red"
        subject.options = { name: name, color: color }

        expect(subject.name).to eq(name)
        expect(subject.color).to eq(color)
      end
    end
  end

  context "setters" do
    subject { Product.new(options: {}) }

    context "string fields" do
      it "sets the value in the jsonb field" do
        name = "Marty McFly"
        color = "red"

        subject.name = name
        subject.color = color

        expect(subject.name).to eq(name)
        expect(subject.color).to eq(color)
      end

      it "preserves nil" do
        subject.name = nil
        expect(subject.name).to be_nil
      end
    end
  end
end
