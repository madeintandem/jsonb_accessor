# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonbAccessor::QueryBuilder do
  describe ".validate_column_name!" do
    subject { JsonbAccessor::QueryBuilder }

    context "when the column exists for the relation" do
      it "is true" do
        expect do
          subject.validate_column_name!(Product.all, :options)
        end.to_not raise_error
        expect do
          subject.validate_column_name!(Product.all, "options")
        end.to_not raise_error
      end
    end

    context "when the column does not exist for the relation" do
      it "is false" do
        error_message = "a column named `nope` does not exist on the `products` table"
        expect do
          subject.validate_column_name!(Product.all, :nope)
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidColumnName, error_message)
        expect do
          subject.validate_column_name!(Product.all, "nope")
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidColumnName, error_message)
      end
    end
  end

  describe ".validate_field_name!" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options, title: :string, description: [:string, store_key: :d]
      end
    end

    context "given a valid field name" do
      it "does not raise an error" do
        expect do
          subject.validate_field_name!(klass.all, :options, :title)
          subject.validate_field_name!(klass.all, :options, "title")
          subject.validate_field_name!(klass.all, :options, "d")
        end.to_not raise_error
      end
    end

    context "given an invalid field name" do
      it "raises an error" do
        expect do
          subject.validate_field_name!(klass.all, :options, "foo")
        end.to raise_error(
          JsonbAccessor::QueryBuilder::InvalidFieldName,
          "`foo` is not a valid field name, valid field names include: `title`, `d`"
        )
      end
    end
  end

  describe ".validate_direction!" do
    context "given a valid direction" do
      it "does not raise an error" do
        expect do
          [:asc, :desc, "asc", "desc"].each do |option|
            subject.validate_direction!(option)
          end
        end.to_not raise_error
      end
    end

    context "given an invalid direction" do
      it "raises an error" do
        expect do
          subject.validate_direction!(:foo)
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidDirection, "`foo` is not a valid direction for ordering, only `asc` and `desc` are accepted")
      end
    end
  end

  describe ".convert_keys_to_store_keys" do
    subject { JsonbAccessor::QueryBuilder }
    let(:attributes) { { foo: "bar", bar: "baz" } }
    let(:store_key_mapping) { { "foo" => "foo", "bar" => "b" } }
    let(:expected) { { "foo" => "bar", "b" => "baz" } }

    it "converts the keys of a given hash into store keys based on the given store key mapping" do
      expect(subject.convert_keys_to_store_keys(attributes, store_key_mapping)).to eq(expected)
    end
  end

  describe ".jsonb_contains" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: title) }
    let!(:other_matching_record) { Product.create!(title: title) }
    let!(:ignored_record) { Product.create!(title: "ignored") }
    subject { Product.all }

    it "is a collection of records that match the query" do
      query = subject.jsonb_contains(:options, title: title)
      expect(query).to exist
      expect(query).to match_array([matching_record, other_matching_record])
    end

    it "escapes sql" do
      expect do
        subject.jsonb_contains(:options, title: "foo\"};delete from products where id = #{matching_record.id}").to_a
      end.to_not raise_error
      expect(subject.count).to eq(3)
    end

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_contains(:nope, title: "foo")
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidColumnName)
      end
    end

    context "table names" do
      let!(:product_category) { ProductCategory.create!(title: "category") }

      before do
        product_category.products << matching_record
        product_category.products << other_matching_record
      end

      it "is not ambigious which table is being referenced" do
        expect do
          subject.joins(:product_category).merge(ProductCategory.jsonb_contains(:options, title: "category")).to_a
        end.to_not raise_error
      end
    end
  end

  describe ".jsonb_excludes" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: title) }
    let!(:other_matching_record) { Product.create!(title: title) }
    let!(:ignored_record) { Product.create!(title: "ignored") }

    subject { Product.all }

    it "is a collection of records that don't match the query" do
      query = subject.jsonb_excludes(:options, title: ignored_record.title)
      expect(query).to exist
      expect(query).to match_array([matching_record, other_matching_record])
    end

    it "escapes sql" do
      expect do
        subject.jsonb_excludes(:options, title: "foo\"};delete from products where id = #{matching_record.id}").to_a
      end.to_not raise_error
      expect(subject.count).to eq(3)
    end

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_excludes(:nope, title: "foo")
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidColumnName)
      end
    end

    context "table names" do
      let!(:product_category) { ProductCategory.create!(title: "category") }

      before do
        product_category.products << matching_record
        product_category.products << other_matching_record
      end

      it "is not ambigious which table is being referenced" do
        expect do
          subject.joins(:product_category).merge(ProductCategory.jsonb_excludes(:options, title: "category")).to_a
        end.to_not raise_error
      end
    end
  end

  describe "#jsonb_number_where" do
    let!(:high_rank_record) { Product.create!(rank: 5) }
    let!(:middle_rank_record) { Product.create!(rank: 4) }
    let!(:low_rank_record) { Product.create!(rank: 0) }
    subject { Product.all }

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_number_where(:nope, :rank, ">", middle_rank_record.rank)
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidColumnName)
      end
    end

    context "greater than" do
      it "is matching records" do
        [:>, :greater_than, :gt, ">", "greater_than", "gt"].each do |operator|
          query = subject.jsonb_number_where(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to eq([high_rank_record])
        end
      end
    end

    context "less than" do
      it "is matching records" do
        [:<, :less_than, :lt, "<", "less_than", "lt"].each do |operator|
          query = subject.jsonb_number_where(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to eq([low_rank_record])
        end
      end
    end

    context "less than or equal to" do
      it "is matching records" do
        [:<=, :less_than_or_equal_to, :lte, "<=", "less_than_or_equal_to", "lte"].each do |operator|
          query = subject.jsonb_number_where(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([low_rank_record, middle_rank_record])
        end
      end
    end

    context "greater than or equal to" do
      it "is matching records" do
        [:>=, :greater_than_or_equal_to, :gte, ">=", "greater_than_or_equal_to", "gte"].each do |operator|
          query = subject.jsonb_number_where(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([high_rank_record, middle_rank_record])
        end
      end
    end
  end

  describe "#jsonb_number_where_not" do
    let!(:high_rank_record) { Product.create!(rank: 5) }
    let!(:middle_rank_record) { Product.create!(rank: 4) }
    let!(:low_rank_record) { Product.create!(rank: 0) }
    subject { Product.all }

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_number_where_not(:nope, :rank, ">", middle_rank_record.rank)
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidColumnName)
      end
    end

    context "greater than" do
      it "excludes matching records" do
        [:>, :greater_than, :gt, ">", "greater_than", "gt"].each do |operator|
          query = subject.jsonb_number_where_not(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([low_rank_record, middle_rank_record])
        end
      end
    end

    context "less than" do
      it "excludes matching records" do
        [:<, :less_than, :lt, "<", "less_than", "lt"].each do |operator|
          query = subject.jsonb_number_where_not(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([high_rank_record, middle_rank_record])
        end
      end
    end

    context "less than or equal to" do
      it "excludes matching records" do
        [:<=, :less_than_or_equal_to, :lte, "<=", "less_than_or_equal_to", "lte"].each do |operator|
          query = subject.jsonb_number_where_not(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([high_rank_record])
        end
      end
    end

    context "greater than or equal to" do
      it "excludes matching records" do
        [:>=, :greater_than_or_equal_to, :gte, ">=", "greater_than_or_equal_to", "gte"].each do |operator|
          query = subject.jsonb_number_where_not(:options, :rank, operator, middle_rank_record.rank)
          expect(query).to exist
          expect(query).to match_array([low_rank_record])
        end
      end
    end
  end

  describe "#jsonb_time_where" do
    let!(:early_record) { Product.create!(made_at: 10.days.ago) }
    let!(:late_record) { Product.create!(made_at: 2.days.from_now) }
    subject { Product.all }

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_time_where(:nope, :made_at, "before", Time.current)
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidColumnName)
      end
    end

    context "before" do
      it "is matching records" do
        [:before, "before"].each do |operator|
          query = subject.jsonb_time_where(:options, :made_at, operator, Time.current)
          expect(query).to exist
          expect(query).to eq([early_record])
        end
      end
    end

    context "after" do
      it "is matching records" do
        [:after, "after"].each do |operator|
          query = subject.jsonb_time_where(:options, :made_at, operator, Time.current)
          expect(query).to exist
          expect(query).to eq([late_record])
        end
      end
    end
  end

  describe "#jsonb_time_where_not" do
    let!(:early_record) { Product.create!(made_at: 10.days.ago) }
    let!(:late_record) { Product.create!(made_at: 2.days.from_now) }
    subject { Product.all }

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_time_where_not(:nope, :made_at, "before", Time.current)
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidColumnName)
      end
    end

    context "before" do
      it "excludes matching records" do
        [:before, "before"].each do |operator|
          query = subject.jsonb_time_where_not(:options, :made_at, operator, Time.current)
          expect(query).to exist
          expect(query).to eq([late_record])
        end
      end
    end

    context "after" do
      it "excludes matching records" do
        [:after, "after"].each do |operator|
          query = subject.jsonb_time_where_not(:options, :made_at, operator, Time.current)
          expect(query).to exist
          expect(query).to eq([early_record])
        end
      end
    end
  end

  describe "#jsonb_where" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: title, rank: 4, made_at: Time.current) }
    let!(:ignored_record) { Product.create!(title: "ignored", rank: 3, made_at: 3.years.ago) }
    let!(:blank_record) { Product.create! }
    subject { Product.all }

    context "contains" do
      it "is matching records" do
        query = subject.jsonb_where(:options, title: title)
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "number queries" do
      it "is records matching the criteria" do
        query = subject.jsonb_where(:options, rank: { greater_than: 3, less_than: 7 })
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "time queries" do
      it "is records matching the criteria" do
        query = subject.jsonb_where(:options, made_at: { before: 2.days.from_now, after: 2.days.ago })
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "smoke test" do
      it "is records matching the criteria" do
        query = subject.jsonb_where(
          :options,
          title: title,
          rank: { greater_than: 3, less_than: 7 },
          made_at: { before: 2.days.from_now, after: 2.days.ago }
        )
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end
  end

  describe "#jsonb_where_not" do
    let(:title) { "title" }
    let!(:matching_record) { Product.create!(title: "not excluded", rank: 3, made_at: 3.years.ago) }
    let!(:ignored_record) { Product.create!(title: title, rank: 4, made_at: Time.current) }
    let!(:blank_record) { Product.create! }
    subject { Product.all }

    context "contains" do
      it "excludes matching records" do
        query = subject.jsonb_where_not(:options, title: ignored_record.title)
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "number queries" do
      it "excludes records matching the criteria" do
        query = subject.jsonb_where_not(:options, rank: { greater_than: 3 })
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "time queries" do
      it "excludes records matching the criteria" do
        query = subject.jsonb_where_not(:options, made_at: { after: 2.days.ago })
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end

    context "smoke test" do
      it "excludes records matching the criteria" do
        query = subject.jsonb_where_not(
          :options,
          title: title,
          rank: { greater_than: 3 },
          made_at: { after: 2.days.ago }
        )
        expect(query).to exist
        expect(query).to eq([matching_record])
      end
    end
  end

  describe "#jsonb_order" do
    let!(:second_product) { Product.create!(title: "B") }
    let!(:last_product) { Product.create!(title: "C") }
    let!(:first_product) { Product.create!(title: "A") }
    let(:ordered_records) { [first_product, second_product, last_product] }
    subject { Product.all }

    it "orders by the given attribute and direction" do
      expect(subject.jsonb_order(:options, :title, :asc)).to eq(ordered_records)
      expect(subject.jsonb_order(:options, :title, :desc)).to eq(ordered_records.reverse)
    end

    context "given an invalid column name" do
      it "raises an error" do
        expect do
          subject.jsonb_order(:nah, :title, :asc)
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidColumnName)
      end
    end

    context "given an invalid field" do
      it "raises an error" do
        expect do
          subject.jsonb_order(:options, :nah, :asc)
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidFieldName)
      end
    end

    context "given an invalid direction" do
      it "raises an error" do
        expect do
          subject.jsonb_order(:options, :title, :nah)
        end.to raise_error(JsonbAccessor::QueryBuilder::InvalidDirection)
      end
    end
  end

  describe "->is_number_query_arguments" do
    subject { JsonbAccessor::IS_NUMBER_QUERY_ARGUMENTS }

    context "not a hash" do
      it "is false" do
        expect(subject.call(nil)).to eq(false)
        expect(subject.call("foo")).to eq(false)
      end
    end

    context "hash that is not for a number query" do
      it "is false" do
        expect(subject.call("before" => 12)).to eq(false)
        expect(subject.call("title" => "foo")).to eq(false)
      end
    end

    context "hash that is for a number query" do
      it "is true" do
        expect(subject.call(greater_than: 5, "less_than" => 10)).to eq(true)
      end
    end
  end

  describe "->is_time_query_arguments" do
    subject { JsonbAccessor::IS_TIME_QUERY_ARGUMENTS }

    context "not a hash" do
      it "is false" do
        expect(subject.call(nil)).to eq(false)
        expect(subject.call("foo")).to eq(false)
      end
    end

    context "hash that is not for a number query" do
      it "is false" do
        expect(subject.call("greater_than" => 12)).to eq(false)
        expect(subject.call("title" => "foo")).to eq(false)
      end
    end

    context "hash that is for a number query" do
      it "is true" do
        expect(subject.call(before: 10, "after" => 5)).to eq(true)
      end
    end
  end
end
