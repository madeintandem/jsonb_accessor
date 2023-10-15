# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2015_04_07_031737) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "product_categories", id: :serial, force: :cascade do |t|
    t.jsonb "options"
  end

  create_table "products", id: :serial, force: :cascade do |t|
    t.jsonb "options"
    t.jsonb "data"
    t.string "string_type"
    t.integer "integer_type"
    t.integer "product_category_id"
    t.boolean "boolean_type"
    t.float "float_type"
    t.time "time_type"
    t.date "date_type"
    t.datetime "datetime_type", precision: nil
    t.decimal "decimal_type"
  end

end
