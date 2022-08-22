# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonbAccessor::Adapters::SqliteAdapter do
  return if ActiveRecord::VERSION::MAJOR < 6

  def build_class(jsonb_accessor_config, &block)
    Class.new(ActiveRecord::Base) do
      def self.name
        "product"
      end

      establish_connection adapter: "sqlite3", database: sqlite_database_path
      connection.create_table :products, force: true do |t|
        t.json :options
        t.json :data

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

      connection.create_table :product_categories, force: true do |t|
        t.json :options
      end

      self.table_name = "products"
      jsonb_accessor :options, jsonb_accessor_config
      instance_eval(&block) if block

      attribute :bang, :string
    end
  end

  it_behaves_like "a model with query methods"
  it_behaves_like "a model with attribute query methods"
end
