$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "jsonb_accessor"
require "pry"
require "pry-nav"
require "pry-doc"
require "database_cleaner"
require "shoulda-matchers"
require "yaml"

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
