$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "jsonb_accessor"
require "pry"
require "pry-nav"
require "pry-doc"
require "database_cleaner"
require "shoulda-matchers"

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
    create_database
  end

  config.before do
    DatabaseCleaner.clean_with(:truncation)
  end
end

def create_database
  ActiveRecord::Base.establish_connection(
    adapter: "postgresql",
    database: "jsonb_accessor",
    username: "postgres"
  )

  ActiveRecord::Base.connection.execute("CREATE EXTENSION jsonb;") rescue ActiveRecord::StatementInvalid
  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS products;")
  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS product_categories;")

  ActiveRecord::Base.connection.create_table(:products) do |t|
    t.jsonb :options
    t.jsonb :data

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

  ActiveRecord::Base.connection.create_table(:product_categories) do |t|
    t.jsonb :options
  end
end
