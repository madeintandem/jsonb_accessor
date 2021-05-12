# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

require "active_record"
include ActiveRecord::Tasks

root = File.expand_path "..", __FILE__
db_dir = File.join(root, "db")
DatabaseTasks.root = root
DatabaseTasks.db_dir = db_dir
DatabaseTasks.database_configuration = YAML.load(File.read(File.join(db_dir, "config.yml")))
DatabaseTasks.migrations_paths = [File.join(db_dir, "migrate")]
DatabaseTasks.env = "test"

task :environment do
  ActiveRecord::Base.configurations = DatabaseTasks.database_configuration
  ActiveRecord::Base.establish_connection DatabaseTasks.env.to_sym
end

load "active_record/railties/databases.rake"

task(default: %i[rubocop spec])
