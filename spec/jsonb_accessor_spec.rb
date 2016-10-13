# frozen_string_literal: true
require "spec_helper"

RSpec.describe JsonbAccessor do
  it "has a version number" do
    expect(JsonbAccessor::VERSION).to_not be nil
  end

  it "is mixed into ActiveRecord::Base" do
    expect(ActiveRecord::Base.ancestors).to include(subject)
  end

  it "defines jsonb_accessor" do
    expect(ActiveRecord::Base).to respond_to(:jsonb_accessor)
  end

  # describe "#jsonb_accessor" do
  #   # context "multiple calls" do
  #   #   let!(:dummy_class) do
  #   #     klass = Class.new(ActiveRecord::Base) do
  #   #       self.table_name = "products"
  #   #     end
  #   #     stub_const("Foo", klass)
  #   #     klass.class_eval { jsonb_accessor :data, :foo }
  #   #     klass
  #   #   end

  #   #   after { JsonbAccessor.send(:remove_const, "JAFoo") }

  #   #   it "can be called twice in a class without issue" do
  #   #     expect do
  #   #       dummy_class.class_eval { jsonb_accessor :options, :bar }
  #   #     end.to_not change { JsonbAccessor::JAFoo }
  #   #   end

  #   #   context do
  #   #     let(:subject) { dummy_class.last }

  #   #     before do
  #   #       dummy_class.class_eval { jsonb_accessor :options, :bar }

  #   #       dummy = dummy_class.new
  #   #       dummy.foo = 5
  #   #       dummy.save!
  #   #     end

  #   #     it "initializes attributes properly" do
  #   #       expect(subject.foo).to eq(5)
  #   #     end

  #   #     it "doesn't mark attributes loaded from the db as dirty" do
  #   #       expect(subject).to be_persisted
  #   #       expect(subject).to_not be_changed
  #   #     end
  #   #   end
  #   # end

  #   # context "namespaced classes" do
  #   #   let(:dummy_class) do
  #   #     klass = Class.new(ActiveRecord::Base) do
  #   #       self.table_name = "products"
  #   #     end
  #   #     stub_const("Foo", Module.new)
  #   #     stub_const("Foo::Bar", klass)
  #   #     klass
  #   #   end

  #   #   it "can be called in a namespaced class" do
  #   #     expect do
  #   #       dummy_class.class_eval { jsonb_accessor :data, :foo }
  #   #     end.to_not raise_error
  #   #   end

  #   #   context "multiple calls" do
  #   #     it "can be called twice in a namespaced class without issue" do
  #   #       expect do
  #   #         dummy_class.class_eval { jsonb_accessor :options, :bar }
  #   #       end.to_not change { JsonbAccessor::JAFooBar }
  #   #     end
  #   #   end
  #   # end

  #   # context "inheritance" do
  #   #   let(:sub_class) { Class.new(Product) }
  #   #   before { stub_const("Foo", sub_class) }
  #   #   after { JsonbAccessor.send(:remove_const, "JAFoo") }

  #   #   it "adds new declared accessor fields" do
  #   #     Foo.class_eval { jsonb_accessor :data, inventory: :boolean }
  #   #     instance = Foo.new
  #   #     instance.title = "1.0"
  #   #     expect(instance).to respond_to(:inventory)
  #   #     expect(instance.title).to eq("1.0")
  #   #   end

  #   #   it "rewrites the type definition from the super class" do
  #   #     Foo.class_eval { jsonb_accessor :data, title: :decimal }
  #   #     instance = Foo.new
  #   #     instance.title = "1.0"
  #   #     expect(instance.title).to eq(1.0)
  #   #   end
  #   # end
  # end

  # context "value setters" do
  #   subject { Product.new }
  #   let(:name) { "Marty McFly" }
  #   let(:count) { 5 }
  #   let(:price) { 2.5 }

  #   before do
  #     subject.name = name
  #     subject.count = count
  #     subject.price = price
  #   end

  #   context "default value fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["name"]).to eq(name)
  #       expect(subject.options["count"]).to eq(count)
  #       expect(subject.options["price"]).to eq(price)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.name).to eq(name)
  #       expect(subject.count).to eq(count)
  #       expect(subject.price).to eq(price)
  #     end
  #   end
  # end

  # context "typed setters" do
  #   subject { Product.new }
  #   let(:title) { "Mister" }
  #   let(:id_value) { 1056 }
  #   let(:name_value) { "John McClane" }
  #   let(:external_id) { 456 }
  #   let(:admin) { true }
  #   let(:approved_on) { Date.new(2015, 3, 25) }
  #   let(:reviewed_at) { DateTime.new(2015, 3, 25, 6, 45, 33) }
  #   let(:precision) { 5.0023 }
  #   let(:reset_at) { Time.new(2015, 4, 5, 6, 7, 8) }
  #   let(:amount_floated) { 52.8892 }
  #   let(:sequential_data) { [5, "foo", 52.8892] }
  #   let(:nicknames) { %w(T-Bone Crushinator) }
  #   let(:rankings) { [1, 4, 2, 5] }
  #   let(:favorited_history) { [true, false, false, true] }
  #   let(:login_days) { [approved_on, Date.new(2013, 2, 25)] }
  #   let(:favorites_at) { [reviewed_at, DateTime.new(2055, 3, 5, 6, 5, 22)] }
  #   let(:prices) { [precision, 123.098753] }
  #   let(:login_times) { [reset_at, Time.new(2005, 4, 7, 6, 1, 3)] }
  #   let(:amounts_floated) { [22.34, amount_floated] }
  #   let(:things) { { "foo" => "bar" } }
  #   let(:stuff) { { "bar" => "foo" } }
  #   let(:a_lot_of_things) { [things, stuff] }
  #   let(:a_lot_of_stuff) { [stuff, things] }

  #   before do
  #     subject.title = title
  #     subject.id_value = id_value
  #     subject.name_value = name_value
  #     subject.external_id = external_id
  #     subject.admin = admin
  #     subject.approved_on = approved_on
  #     subject.reviewed_at = reviewed_at
  #     subject.precision = precision
  #     subject.reset_at = reset_at
  #     subject.amount_floated = amount_floated
  #     subject.sequential_data = sequential_data
  #     subject.nicknames = nicknames
  #     subject.rankings = rankings
  #     subject.favorited_history = favorited_history
  #     subject.login_days = login_days
  #     subject.favorites_at = favorites_at
  #     subject.prices = prices
  #     subject.login_times = login_times
  #     subject.amounts_floated = amounts_floated
  #     subject.things = things
  #     subject.stuff = stuff
  #     subject.a_lot_of_things = a_lot_of_things
  #     subject.a_lot_of_stuff = a_lot_of_stuff
  #   end

  #   context "string fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["title"]).to eq(title)
  #     end

  #     it "coerces the value" do
  #       subject.title = 5
  #       expect(subject.title).to eq("5")
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.title).to eq(title)
  #     end
  #   end

  #   context "value fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["id_value"]).to eq(id_value)
  #       expect(subject.options["name_value"]).to eq(name_value)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.name_value).to eq(name_value)
  #       expect(subject.id_value).to eq(id_value)
  #     end
  #   end

  #   context "integer fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["external_id"]).to eq(external_id)
  #     end

  #     it "coerces the value" do
  #       subject.external_id = "23"
  #       expect(subject.external_id).to eq(23)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.external_id).to eq(external_id)
  #     end
  #   end

  #   context "boolean fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["admin"]).to eq(admin)
  #     end

  #     # ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES.each do |value|
  #     #   it "coerces the value to false when the value is '#{value}'" do
  #     #     subject.admin = value
  #     #     expect(subject.admin).to eq(false)
  #     #   end
  #     # end

  #     # ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.each do |value|
  #     #   it "coerces the value to true when the value is '#{value}'" do
  #     #     subject.admin = value
  #     #     expect(subject.admin).to eq(true)
  #     #   end
  #     # end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.admin).to eq(admin)
  #     end
  #   end

  #   context "date fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["approved_on"]).to eq(approved_on.to_s)
  #     end

  #     it "coerces the value" do
  #       subject.approved_on = approved_on.to_s
  #       expect(subject.approved_on).to eq(approved_on)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.approved_on).to eq(approved_on)
  #     end
  #   end

  #   context "date_time fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(DateTime.parse(subject.options["reviewed_at"]).to_s).to eq(reviewed_at.to_s)
  #     end

  #     it "coerces the value" do
  #       subject.reviewed_at = reviewed_at.to_s
  #       expect(subject.reviewed_at).to eq(reviewed_at)
  #     end

  #     it "coerces infinity" do
  #       subject.reviewed_at = "infinity"
  #       expect(subject.reviewed_at).to eq(::Float::INFINITY)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.reviewed_at).to eq(reviewed_at)
  #     end
  #   end

  #   context "decimal fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["precision"]).to eq(precision.to_s)
  #     end

  #     it "coerces the value" do
  #       subject.precision = precision.to_s
  #       expect(subject.precision).to eq(precision)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.precision).to eq(precision)
  #     end

  #     it "uses the postgres decimal type" do
  #       expect(JsonbAccessor::TypeHelper.fetch(:decimal)).to be_a(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal)
  #     end
  #   end

  #   context "time fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(Time.parse(subject.options["reset_at"]).to_s).to eq(reset_at.to_s)
  #     end

  #     it "coerces the value" do
  #       subject.reset_at = reset_at.to_s
  #       expect(subject.reset_at.hour).to eq(reset_at.hour)
  #       expect(subject.reset_at.min).to eq(reset_at.min)
  #       expect(subject.reset_at.sec).to eq(reset_at.sec)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.reset_at.hour).to eq(reset_at.hour)
  #       expect(subject.reset_at.min).to eq(reset_at.min)
  #       expect(subject.reset_at.sec).to eq(reset_at.sec)
  #     end
  #   end

  #   context "float fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["amount_floated"]).to eq(amount_floated)
  #     end

  #     it "coerces the value" do
  #       subject.amount_floated = amount_floated.to_s
  #       expect(subject.amount_floated).to eq(amount_floated)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.amount_floated).to eq(amount_floated)
  #     end
  #   end

  #   context "array fields" do
  #     context "untyped array fields" do
  #       it "sets the value in the jsonb field" do
  #         expect(subject.options["sequential_data"]).to eq(sequential_data)
  #       end

  #       it "preserves the value after a trip to the database" do
  #         subject.save!
  #         subject.reload
  #         expect(subject.sequential_data).to eq(sequential_data)
  #       end
  #     end

  #     context "typed array fields" do
  #       context "string typed" do
  #         it "sets the value in the jsonb field" do
  #           expect(subject.options["nicknames"]).to eq(nicknames)
  #         end

  #         it "coerces the value" do
  #           subject.nicknames = [5]
  #           expect(subject.nicknames).to eq(["5"])
  #         end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.nicknames).to eq(nicknames)
  #         end
  #       end

  #       context "integer typed" do
  #         it "sets the value in the jsonb field" do
  #           expect(subject.options["rankings"]).to eq(rankings)
  #         end

  #         it "coerces the value" do
  #           subject.rankings = %w(5)
  #           expect(subject.rankings).to eq([5])
  #         end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.rankings).to eq(rankings)
  #         end
  #       end

  #       context "boolean typed" do
  #         it "sets the value in the jsonb field" do
  #           expect(subject.options["favorited_history"]).to eq(favorited_history)
  #         end

  #         # ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES.each do |value|
  #         #   it "coerces the value to false when the value is '#{value}'" do
  #         #     subject.favorited_history = [value]
  #         #     expect(subject.favorited_history).to eq([false])
  #         #   end
  #         # end

  #         # ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.each do |value|
  #         #   it "coerces the value to true when the value is '#{value}'" do
  #         #     subject.favorited_history = [value]
  #         #     expect(subject.favorited_history).to eq([true])
  #         #   end
  #         # end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.favorited_history).to eq(favorited_history)
  #         end
  #       end

  #       context "date typed" do
  #         it "sets the value in the jsonb field" do
  #           expect(subject.options["login_days"]).to eq(login_days.map(&:to_s))
  #         end

  #         it "coerces the value" do
  #           subject.login_days = login_days.map(&:to_s)
  #           expect(subject.login_days).to eq(login_days)
  #         end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.login_days).to eq(login_days)
  #         end
  #       end

  #       context "date_time typed" do
  #         it "sets the value in the jsonb field" do
  #           jsonb_field_value = subject.options["favorites_at"].map do |value|
  #             DateTime.parse(value).to_s
  #           end
  #           expect(jsonb_field_value).to eq(favorites_at.map(&:to_s))
  #         end

  #         it "coerces the value" do
  #           subject.favorites_at = favorites_at.map(&:to_s)
  #           expect(subject.favorites_at).to eq(favorites_at)
  #         end

  #         it "coerces infinity" do
  #           subject.favorites_at = ["infinity"]
  #           expect(subject.favorites_at).to eq([::Float::INFINITY])
  #         end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.favorites_at).to eq(favorites_at)
  #         end
  #       end

  #       context "decimal typed" do
  #         it "sets the value in the jsonb field" do
  #           expect(subject.options["prices"]).to eq(prices.map(&:to_s))
  #         end

  #         it "coerces the value" do
  #           subject.prices = prices.map(&:to_s)
  #           expect(subject.prices).to eq(prices)
  #         end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.prices).to eq(prices)
  #         end

  #         it "uses the postgres decimal type" do
  #           subtype = JsonbAccessor::TypeHelper.fetch(:decimal_array).subtype
  #           expect(subtype).to be_a(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal)
  #         end
  #       end

  #       context "time typed" do
  #         it "sets the value in the jsonb field" do
  #           jsonb_field_value = subject.options["login_times"].map do |value|
  #             Time.parse(value).to_s
  #           end
  #           expect(jsonb_field_value).to eq(login_times.map(&:to_s))
  #         end

  #         it "coerces the value" do
  #           subject.login_times = login_times.map(&:to_s)
  #           expect(subject.login_times).to be_present
  #           subject.login_times.each_with_index do |time, i|
  #             expect(time.hour).to eq(login_times[i].hour)
  #             expect(time.min).to eq(login_times[i].min)
  #             expect(time.sec).to eq(login_times[i].sec)
  #           end
  #         end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.login_times).to be_present
  #           subject.login_times.each_with_index do |time, i|
  #             expect(time.hour).to eq(login_times[i].hour)
  #             expect(time.min).to eq(login_times[i].min)
  #             expect(time.sec).to eq(login_times[i].sec)
  #           end
  #         end
  #       end

  #       context "float typed" do
  #         it "sets the value in the jsonb field" do
  #           expect(subject.options["amounts_floated"]).to eq(amounts_floated)
  #         end

  #         it "coerces the value" do
  #           subject.amounts_floated = amounts_floated.map(&:to_s)
  #           expect(subject.amounts_floated).to eq(amounts_floated)
  #         end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.amounts_floated).to eq(amounts_floated)
  #         end
  #       end

  #       context "json typed" do
  #         it "sets the value in the jsonb field" do
  #           expect(subject.options["a_lot_of_things"]).to eq(a_lot_of_things)
  #         end

  #         it "coerces the value" do
  #           subject.a_lot_of_things = a_lot_of_things.map(&:to_json)
  #           expect(subject.a_lot_of_things).to eq(a_lot_of_things)
  #         end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.a_lot_of_things).to eq(a_lot_of_things)
  #         end
  #       end

  #       context "jsonb typed" do
  #         it "sets the value in the jsonb field" do
  #           expect(subject.options["a_lot_of_stuff"]).to eq(a_lot_of_stuff)
  #         end

  #         it "coerces the value" do
  #           subject.a_lot_of_stuff = a_lot_of_stuff.map(&:to_json)
  #           expect(subject.a_lot_of_stuff).to eq(a_lot_of_stuff)
  #         end

  #         it "preserves the value after a trip to the database" do
  #           subject.save!
  #           subject.reload
  #           expect(subject.a_lot_of_stuff).to eq(a_lot_of_stuff)
  #         end
  #       end
  #     end
  #   end

  #   context "json fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["things"]).to eq(things)
  #     end

  #     it "coerces the value" do
  #       subject.things = things.to_json
  #       expect(subject.things).to eq(things)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.things).to eq(things)
  #     end
  #   end

  #   context "jsonb fields" do
  #     it "sets the value in the jsonb field" do
  #       expect(subject.options["stuff"]).to eq(stuff)
  #     end

  #     it "coerces the value" do
  #       subject.stuff = stuff.to_json
  #       expect(subject.stuff).to eq(stuff)
  #     end

  #     it "preserves the value after a trip to the database" do
  #       subject.save!
  #       subject.reload
  #       expect(subject.stuff).to eq(stuff)
  #     end
  #   end
  # end

  # # context "nested fields" do
  # #   it "creates a namespace named for the class, jsonb attribute, and nested attributes" do
  # #     expect(defined?(JsonbAccessor::JAProduct)).to eq("constant")
  # #     expect(defined?(JsonbAccessor::JAProduct::JAOptions)).to eq("constant")
  # #     expect(defined?(JsonbAccessor::JAProduct::JAOptions::JADocument)).to eq("constant")
  # #     expect(defined?(JsonbAccessor::JAProduct::JAOptions::JADocument::JANested)).to eq("constant")
  # #   end

  # #   context "getters" do
  # #     subject { Product.new }

  # #     before do
  # #       subject.save!
  # #       subject.reload
  # #     end

  # #     it "exists" do
  # #       expect { subject.document.nested.are }.to_not raise_error
  # #     end
  # #   end

  # #   context "setters" do
  # #     let(:document_class) { JsonbAccessor::JAProduct::JAOptions::JADocument }
  # #     subject { Product.new }

  # #     it "sets itself a the object's parent" do
  # #       expect(subject.document.parent).to eq(subject)
  # #     end

  # #     context "a hash" do
  # #       before do
  # #         subject.document = { nested: { are: "here" } }.with_indifferent_access
  # #       end

  # #       it "creates an instance of the correct dynamic class" do
  # #         expect(subject.document).to be_a(document_class)
  # #       end

  # #       it "puts the dynamic class instance's attributes into the jsonb field" do
  # #         expect(subject.options["document"]).to eq(subject.document.attributes)
  # #       end
  # #     end

  # #     context "a dynamic class" do
  # #       let(:document) { document_class.new(nested: nil) }
  # #       before { subject.document = document }

  # #       it "sets the instance" do
  # #         expect(subject.document.attributes).to eq(document.attributes)
  # #       end

  # #       it "puts the dynamic class instance's attributes in the jsonb field" do
  # #         expect(subject.options["document"]).to eq(document.attributes)
  # #       end
  # #     end

  # #     context "nil" do
  # #       before do
  # #         subject.options["document"] = { not: :empty }
  # #         subject.document = nil
  # #       end

  # #       it "sets the attribute to an empty instance of the dynamic class" do
  # #         expect(subject.document.attributes).to eq("nested" => {})
  # #       end

  # #       it "clears the associated attributes in the jsonb field" do
  # #         expect(subject.options["document"]).to eq("nested" => {})
  # #       end
  # #     end

  # #     context "anything else" do
  # #       it "raises an error" do
  # #         expect { subject.document = 5 }.to raise_error(JsonbAccessor::UnknownValue)
  # #       end
  # #     end
  # #   end
  # # end

  # # context "deeply nested setters" do
  # #   let(:value) { "some value" }
  # #   subject do
  # #     Product.create!
  # #   end

  # #   before do
  # #     subject.document.nested.are = value
  # #   end

  # #   it "changes the jsonb field" do
  # #     expect(subject.options["document"]["nested"]["are"]).to eq(value)
  # #   end

  # #   it "persists after a trip to the database" do
  # #     expect(subject.options["document"]["nested"]["are"]).to eq(value)
  # #     subject.save!
  # #     expect(subject.reload.options["document"]["nested"]["are"]).to eq(value)
  # #     expect(subject.reload.document.nested.are).to eq(value)
  # #   end
  # # end

  # # describe ".<field_name>_classes" do
  # #   it "is a mapping of attribute names to dynamically created classes" do
  # #     expect(Product.options_classes).to eq(document: JsonbAccessor::JAProduct::JAOptions::JADocument)
  # #   end

  # #   context "delegation" do
  # #     subject { Product.new }
  # #     it { is_expected.to delegate_method(:options_classes).to(:class) }
  # #   end
  # # end

  # describe "attributes" do
  #   subject { Product.new }

  #   it "defines jsonb accessor fields as attributes" do
  #     ALL_FIELDS.each do |field|
  #       expect(subject.attribute_names).to include(field.to_s)
  #     end
  #   end
  # end

  # context "overriding getters and setters" do
  #   subject { OtherProduct.new }

  #   context "setters" do
  #     it "can be wrapped" do
  #       subject.title = "Duke"
  #       expect(subject.options["title"]).to eq("DUKE")
  #     end
  #   end

  #   context "getters" do
  #     it "can be wrapped" do
  #       subject.title = "COUNT"
  #       expect(subject.title).to eq("count")
  #     end
  #   end
  # end

  # # describe "#reload" do
  # #   let(:value) { "value" }

  # #   before do
  # #     subject.save!
  # #     subject.reload
  # #     subject.document.nested.are = value
  # #     subject.save!
  # #   end

  # #   context do
  # #     subject { Product.new }

  # #     it "works with nested attributes" do
  # #       subject.reload
  # #       expect(subject.document.nested.are).to eq(value)
  # #     end

  # #     it "is itself" do
  # #       expect(subject.reload).to eq(subject)
  # #     end
  # #   end

  # #   context "overriding" do
  # #     subject do
  # #       OtherProduct.new.tap do |other_product|
  # #         other_product.save!
  # #         other_product.reload
  # #       end
  # #     end

  # #     it "can be wrapped" do
  # #       expect(subject.reload).to eq(:wrapped)
  # #       expect(subject.document.nested.are).to eq(value)
  # #     end
  # #   end
  # # end

  # describe "#<jsonb_attribute>=" do
  #   subject { Product.new }
  #   let(:title) { "new title" }

  #   before do
  #     subject.title = "old title"
  #     subject.options = { title: title }
  #   end

  #   it "updates the jsonb attribute" do
  #     expect(subject.options["title"]).to eq(title)
  #   end

  #   it "updates the declared jsonb field attributes" do
  #     expect(subject.title).to eq(title)
  #   end

  #   it "clears attributes that are not in the assigned hash" do
  #     subject.options = {}
  #     expect(subject.title).to be_nil
  #   end

  #   context "wrapping the setter" do
  #     subject { OtherProduct.new }

  #     it "can be overriden" do
  #       subject.options = {}
  #       expect(subject.title).to eq(title)
  #     end
  #   end
  # end

  # context "scopes" do
  #   let(:title) { "foo" }
  #   let(:right_now) { Time.now.utc }
  #   let!(:ignored_product) { Product.create!(title: "bar", rankings: [2]) }
  #   let!(:matching_product) do
  #     Product.create!(
  #       title: title,
  #       external_id: 3,
  #       admin: true,
  #       a_big_number: 23,
  #       reviewed_at: right_now,
  #       reset_at: right_now,
  #       approved_on: right_now,
  #       rankings: [1, 3]
  #     )
  #   end

  #   let!(:other_matching_product) do
  #     Product.create!(
  #       title: title,
  #       admin: false,
  #       rankings: [3],
  #       document: { nested: { are: "0" } }
  #     )
  #   end

  #   describe "#<jsonb_attribute_name>_contains" do
  #     it "is a collection of records that match the query" do
  #       query = Product.options_contains(title: title)
  #       expect(query).to exist
  #       expect(query).to match_array([matching_product, other_matching_product])
  #     end

  #     it "escapes sql" do
  #       expect do
  #         Product.options_contains(title: "foo\"};delete from products where id = #{matching_product.id}").to_a
  #       end.to_not raise_error
  #     end

  #     context "table names" do
  #       let!(:product_category) { ProductCategory.create!(title: "category") }

  #       before do
  #         product_category.products << matching_product
  #         product_category.products << other_matching_product
  #       end

  #       it "is not ambigious which table is being referenced" do
  #         expect do
  #           Product.joins(:product_category).merge(ProductCategory.options_contains(title: "category")).to_a
  #         end.to_not raise_error
  #       end
  #     end

  #     context "type casting" do
  #       it "type casts values properly" do
  #         expect(Product.options_contains(external_id: "3")).to eq([matching_product])
  #       end

  #       it "types casts nested attributes" do
  #         expect(Product.options_contains(document: { nested: { are: 0 } })).to eq([other_matching_product])
  #       end
  #     end
  #   end

  #   describe "#with_<field name>" do
  #     it "is all records associated with the given field" do
  #       expect(Product).to receive(:options_contains).and_call_original
  #       expect(Product.with_title(title)).to match_array([matching_product, other_matching_product])
  #     end
  #   end

  #   context "boolean" do
  #     it "provides #is_<field>" do
  #       expect(Product.is_admin).to eq([matching_product])
  #     end

  #     it "provides #not_<field>" do
  #       expect(Product.not_admin).to eq([other_matching_product])
  #     end
  #   end

  #   context "float, decimal, integer, big integer" do
  #     let!(:largest_product) { Product.create!(external_id: 100, precision: 100.0, amount_floated: 100.0, a_big_number: 1_000_000, reviewed_at: right_now + 10.days) }
  #     let!(:middle_product) { matching_product }
  #     let!(:smallest_product) { Product.create!(external_id: -20, precision: -20.0, amount_floated: -20.0, a_big_number: -1_000_000, reviewed_at: right_now - 10.days) }

  #     describe "#<field>_lt" do
  #       it "is products that are less than the argument" do
  #         expect(Product.external_id_lt(3)).to eq([smallest_product])
  #       end

  #       it "type casts its argument" do
  #         expect(Product.external_id_lt("3")).to eq([smallest_product])
  #       end

  #       it "escapes sql" do
  #         expect do
  #           Product.external_id_lt("22\"};delete from products where id = #{matching_product.id}")
  #         end.to_not raise_error
  #       end

  #       it "supports floats" do
  #         expect(Product.amount_floated_lt(-19.9999999)).to eq([smallest_product])
  #         expect(Product.amount_floated_lt(-20)).to be_empty
  #       end

  #       it "supports decimals" do
  #         expect(Product.precision_lt(-19.9999999)).to eq([smallest_product])
  #         expect(Product.precision_lt(-20)).to be_empty
  #       end

  #       it "supports big integers" do
  #         expect(Product.a_big_number_lt(-999_999)).to eq([smallest_product])
  #         expect(Product.a_big_number_lt(-1_000_000)).to be_empty
  #       end
  #     end

  #     describe "#<field>_lte" do
  #       it "is products that are less than or equal to the argument" do
  #         expect(Product.external_id_lte(3)).to match_array([smallest_product, middle_product])
  #       end

  #       it "type casts its argument" do
  #         expect(Product.external_id_lte("2")).to eq([smallest_product])
  #       end

  #       it "escapes sql" do
  #         expect do
  #           Product.external_id_lte("22\"};delete from products where id = #{matching_product.id}")
  #         end.to_not raise_error
  #       end

  #       it "supports floats" do
  #         expect(Product.amount_floated_lte(-20.0)).to eq([smallest_product])
  #         expect(Product.amount_floated_lte(-20.000000001)).to be_empty
  #       end

  #       it "supports decimals" do
  #         expect(Product.precision_lte(-20.0)).to eq([smallest_product])
  #         expect(Product.precision_lte(-20.000000001)).to be_empty
  #       end

  #       it "supports big integers" do
  #         expect(Product.a_big_number_lte(-1_000_000)).to eq([smallest_product])
  #         expect(Product.a_big_number_lte(-1_000_001)).to be_empty
  #       end
  #     end

  #     describe "#<field>_gte" do
  #       it "is products that are greater than or equal to the argument" do
  #         expect(Product.external_id_gte(3)).to match_array([largest_product, middle_product])
  #       end

  #       it "type casts its argument" do
  #         expect(Product.external_id_gte("4")).to eq([largest_product])
  #       end

  #       it "escapes sql" do
  #         expect do
  #           Product.external_id_gte("22\"};delete from products where id = #{matching_product.id}")
  #         end.to_not raise_error
  #       end

  #       it "supports floats" do
  #         expect(Product.amount_floated_gte(100)).to eq([largest_product])
  #         expect(Product.amount_floated_gte(100.000001)).to be_empty
  #       end

  #       it "supports decimals" do
  #         expect(Product.precision_gte(100)).to eq([largest_product])
  #         expect(Product.precision_gte(100.0000001)).to be_empty
  #       end

  #       it "supports big integers" do
  #         expect(Product.a_big_number_gte(1_000_000)).to eq([largest_product])
  #         expect(Product.a_big_number_gte(1_000_001)).to be_empty
  #       end
  #     end

  #     describe "#<field>_gt" do
  #       it "is products that are greater than to the argument" do
  #         expect(Product.external_id_gt(3)).to match_array([largest_product])
  #       end

  #       it "type casts its argument" do
  #         expect(Product.external_id_gt("3")).to eq([largest_product])
  #       end

  #       it "escapes sql" do
  #         expect do
  #           Product.external_id_gt("22\"};delete from products where id = #{matching_product.id}")
  #         end.to_not raise_error
  #       end

  #       it "supports floats" do
  #         expect(Product.amount_floated_gt(99.9999999)).to eq([largest_product])
  #         expect(Product.amount_floated_gt(100.0)).to be_empty
  #       end

  #       it "supports decimals" do
  #         expect(Product.precision_gt(99.9999999)).to eq([largest_product])
  #         expect(Product.precision_gt(100.0)).to be_empty
  #       end

  #       it "supports big integers" do
  #         expect(Product.a_big_number_gt(999_999)).to eq([largest_product])
  #         expect(Product.a_big_number_gt(1_000_000)).to be_empty
  #       end
  #     end
  #   end

  #   context "date time" do
  #     let(:a_second_ago) { right_now - 1.second }
  #     let(:a_second_from_now) { right_now + 1.seconds }
  #     let(:fifty_hours_from_now) { right_now + 50.hours }
  #     let(:fifty_hours_ago) { right_now - 50.hours }

  #     let!(:largest_product) { Product.create!(reviewed_at: fifty_hours_from_now, reset_at: fifty_hours_from_now, approved_on: fifty_hours_from_now) }
  #     let!(:middle_product) { matching_product }
  #     let!(:smallest_product) { Product.create!(reviewed_at: fifty_hours_ago, reset_at: fifty_hours_ago, approved_on: fifty_hours_ago) }

  #     describe "#<field>_before" do
  #       it "is products before the given date time" do
  #         expect(Product.reviewed_at_before(a_second_ago)).to eq([smallest_product])
  #         expect(Product.reviewed_at_before(a_second_from_now)).to match_array([smallest_product, middle_product])
  #       end

  #       it "supports json string date times" do
  #         expect(Product.reviewed_at_before(a_second_ago.to_json)).to eq([smallest_product])
  #       end
  #     end

  #     describe "#<field>_after" do
  #       it "is products after the given date time" do
  #         expect(Product.reviewed_at_after(a_second_from_now)).to eq([largest_product])
  #         expect(Product.reviewed_at_after(a_second_ago)).to match_array([largest_product, middle_product])
  #       end

  #       it "supports json string date times" do
  #         expect(Product.reviewed_at_after(a_second_from_now.utc.to_json)).to eq([largest_product])
  #       end
  #     end
  #   end

  #   context "date" do
  #     let(:todays_date) { right_now.to_date }
  #     let(:a_day_ago) { todays_date - 1.day }
  #     let(:a_day_from_now) { todays_date + 1.day }
  #     let(:fifty_days_from_now) { todays_date + 50.days }
  #     let(:fifty_days_ago) { todays_date - 50.days }
  #     let!(:largest_product) { Product.create!(approved_on: fifty_days_from_now) }
  #     let!(:middle_product) { matching_product }
  #     let!(:smallest_product) { Product.create!(approved_on: fifty_days_ago) }

  #     describe "#<field>_before" do
  #       it "is products before the given date" do
  #         expect(Product.approved_on_before(a_day_ago)).to eq([smallest_product])
  #         expect(Product.approved_on_before(a_day_from_now)).to match_array([smallest_product, middle_product])
  #       end

  #       it "supports json strings" do
  #         expect(Product.approved_on_before(a_day_ago.to_json)).to eq([smallest_product])
  #       end
  #     end

  #     describe "#<field>_after" do
  #       it "is products after the given date" do
  #         expect(Product.approved_on_after(a_day_from_now)).to eq([largest_product])
  #         expect(Product.approved_on_after(a_day_ago)).to match_array([largest_product, middle_product])
  #       end

  #       it "supports json strings" do
  #         expect(Product.approved_on_after(a_day_from_now.to_json)).to eq([largest_product])
  #       end
  #     end
  #   end

  #   describe "#<array_field>_contains" do
  #     it "is all records that contain the argument" do
  #       expect(Product.rankings_contains(3)).to match_array([matching_product, other_matching_product])
  #       expect(Product.rankings_contains(1)).to match_array([matching_product])
  #     end
  #   end
  # end

  # # context "ActionDispatch clean up" do
  # #   context "ActionDispatch defined and in development" do
  # #     before do
  # #       stub_const("ActionDispatch", ActionDispatchAlias)
  # #       ENV["RACK_ENV"] = "development"
  # #     end

  # #     after { ENV["RACK_ENV"] = "test" }

  # #     let!(:dummy_class) do
  # #       klass = Class.new(ActiveRecord::Base) do
  # #         self.table_name = "products"
  # #       end
  # #       stub_const("FooBaz", klass)
  # #       klass.class_eval { jsonb_accessor :options, foo: { bar: :integer } }
  # #     end

  # #     it "removes dynamically generated classes when cleanup happens" do
  # #       expect(defined?(JsonbAccessor::JAFooBaz)).to eq("constant")
  # #       ActionDispatch::Reloader.cleanup!
  # #       expect(defined?(JsonbAccessor::JAFooBaz)).to be_nil
  # #       expect { ActionDispatch::Reloader.cleanup! }.to_not raise_error
  # #     end
  # #   end

  # #   context "ActionDispatch defined but not in development" do
  # #     before do
  # #       stub_const("ActionDispatch", ActionDispatchAlias)
  # #     end

  # #     let(:dummy_class) do
  # #       klass = Class.new(ActiveRecord::Base) do
  # #         self.table_name = "products"
  # #       end
  # #       stub_const("BazBar", klass)
  # #       klass.class_eval { jsonb_accessor :options, foo: { bar: :integer } }
  # #     end

  # #     it "does nothing" do
  # #       expect(ActionDispatch::Reloader).to_not receive(:to_cleanup)
  # #       dummy_class
  # #     end
  # #   end

  # #   context "ActionDispatch is not defined" do
  # #     let(:dummy_class) do
  # #       klass = Class.new(ActiveRecord::Base) do
  # #         self.table_name = "products"
  # #       end
  # #       stub_const("FooBarBaz", klass)
  # #       klass.class_eval { jsonb_accessor :options, foo: { bar: :integer } }
  # #     end

  # #     it "does nothing" do
  # #       expect { dummy_class }.to_not raise_error
  # #     end
  # #   end
  # # end

  # context "typical active record queries" do
  #   context "using select" do
  #     it "does not raise an attribute missing error (or any other error)" do
  #       Product.create!
  #       expect { Product.select(:id).to_a }.to_not raise_error
  #     end
  #   end

  #   context "using `includes` to eager load a jsonb accessor model" do
  #     it "does not raise an error" do
  #       product_category = ProductCategory.create!(title: "what")
  #       Product.create!(product_category: product_category)
  #       expect { Product.includes(:product_category).order("products.id").to_a }.to_not raise_error
  #     end
  #   end
  # end
end
