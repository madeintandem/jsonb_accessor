# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2015_04_07_031737) do

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
    t.datetime "datetime_type"
    t.decimal "decimal_type"
  end

end
