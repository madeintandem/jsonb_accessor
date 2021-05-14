# frozen_string_literal: true

class SetUpTestingDb < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
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

    create_table :product_categories do |t|
      t.jsonb :options
    end
  end
end
