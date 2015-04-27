$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "jsonb_accessor"
require "pry"
require "pry-nav"
require "pry-doc"
require "awesome_print"
require "database_cleaner"
require "shoulda-matchers"
require "yaml"

VALUE_FIELDS = [:count, :name, :price]
TYPED_FIELDS = {
  title: :string,
  name_value: :value,
  id_value: :value,
  external_id: :integer,
  admin: :boolean,
  approved_on: :date,
  reviewed_at: :date_time,
  precision: :decimal,
  reset_at: :time,
  amount_floated: :float,
  sequential_data: :array,
  things: :json,
  stuff: :jsonb,
  a_lot_of_things: :json_array,
  a_lot_of_stuff: :jsonb_array,
  nicknames: :string_array,
  rankings: :integer_array,
  favorited_history: :boolean_array,
  login_days: :date_array,
  favorites_at: :date_time_array,
  prices: :decimal_array,
  login_times: :time_array,
  amounts_floated: :float_array,
  document: {
    nested: {
      values: :array,
      are: :string
    },
    here: :string
  }
}
ALL_FIELDS = VALUE_FIELDS + TYPED_FIELDS.keys

class Product < ActiveRecord::Base
  jsonb_accessor :options, *VALUE_FIELDS, TYPED_FIELDS
  belongs_to :product_category
end

class OtherProduct < ActiveRecord::Base
  self.table_name = "products"
  jsonb_accessor :options, title: :string, document: { nested: { are: :string } }

  def options=(value)
    value["title"] = "new title"
    super
  end

  def title=(value)
    super(value.try(:upcase))
  end

  def title
    super.try(:downcase)
  end

  def reload
    super
    :wrapped
  end
end

class ProductCategory < ActiveRecord::Base
  jsonb_accessor :options, title: :string
  has_many :products
end

RSpec::Matchers.define :alias_the_method do |method_name|
  match do |actual|
    if actual.respond_to?(method_name) && actual.respond_to?(@other_method_name)
      aliased_method = actual.method(@other_method_name)
      original_method = actual.method(method_name)
      aliased_method.original_name == original_method.name
    end
  end

  chain :to do |other_method_name|
    @other_method_name = other_method_name
  end
end

RSpec::Matchers.define :attr_accessorize do |attribute_name|
  match do |actual|
    if actual.respond_to?(attribute_name) && actual.respond_to?("#{attribute_name}=")
      value = (1..5).to_a.sample
      actual.send("#{attribute_name}=", value)
      actual.send(attribute_name) == value
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  config.default_formatter = "doc" if config.files_to_run.one?

  config.profile_examples = 0

  config.order = :random

  Kernel.srand config.seed

  config.before :suite do
    dbconfig = YAML.load(File.open("db/config.yml"))
    ActiveRecord::Base.establish_connection(dbconfig["test"])
  end

  config.before do
    DatabaseCleaner.clean_with(:truncation)
  end
end
