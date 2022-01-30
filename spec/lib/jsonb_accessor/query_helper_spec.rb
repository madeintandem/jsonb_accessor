# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonbAccessor::QueryHelper do
  describe ".validate_column_name!" do
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
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidColumnName, error_message)
        expect do
          subject.validate_column_name!(Product.all, "nope")
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidColumnName, error_message)
      end
    end
  end

  describe ".validate_field_name!" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "products"
        jsonb_accessor :options, title: :string, description: [:string, { store_key: :d }]
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
          JsonbAccessor::QueryHelper::InvalidFieldName,
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
        end.to raise_error(JsonbAccessor::QueryHelper::InvalidDirection, "`foo` is not a valid direction for ordering, only `asc` and `desc` are accepted")
      end
    end
  end

  describe ".number_query_arguments?" do
    context "not a hash" do
      it "is false" do
        expect(subject.number_query_arguments?(nil)).to eq(false)
        expect(subject.number_query_arguments?("foo")).to eq(false)
      end
    end

    context "hash that is not for a number query" do
      it "is false" do
        expect(subject.number_query_arguments?("before" => 12)).to eq(false)
        expect(subject.number_query_arguments?("title" => "foo")).to eq(false)
      end
    end

    context "hash that is for a number query" do
      it "is true" do
        expect(subject.number_query_arguments?(greater_than: 5, "less_than" => 10)).to eq(true)
      end
    end
  end

  describe ".time_query_arguments?" do
    context "not a hash" do
      it "is false" do
        expect(subject.time_query_arguments?(nil)).to eq(false)
        expect(subject.time_query_arguments?("foo")).to eq(false)
      end
    end

    context "hash that is not for a number query" do
      it "is false" do
        expect(subject.time_query_arguments?("greater_than" => 12)).to eq(false)
        expect(subject.time_query_arguments?("title" => "foo")).to eq(false)
      end
    end

    context "hash that is for a number query" do
      it "is true" do
        expect(subject.time_query_arguments?(before: 10, "after" => 5)).to eq(true)
      end
    end
  end

  describe ".convert_time_ranges" do
    let(:start_time) { 3.days.ago }
    let(:end_time) { 3.days.from_now }

    let(:start_date) { start_time.to_date }
    let(:end_date) { end_time.to_date }

    context "times" do
      it "converts time ranges into `before` and `after` hashes" do
        expect(subject.convert_time_ranges(foo: start_time..end_time)).to eq(foo: { after: start_time, before: end_time })
      end
    end

    context "dates" do
      it "converts time ranges into `before` and `after` hashes" do
        expect(subject.convert_time_ranges(foo: start_date..end_date)).to eq(foo: { after: start_date, before: end_date })
      end
    end

    context "non ranges" do
      it "preserves them" do
        expect(subject.convert_time_ranges(foo: start_time)).to eq(foo: start_time)
        expect(subject.convert_time_ranges(bar: 9)).to eq(bar: 9)
      end
    end

    context "number ranges" do
      it "preserves them" do
        expect(subject.convert_time_ranges(foo: 1..3)).to eq(foo: 1..3)
      end
    end
  end

  describe ".convert_number_ranges" do
    context "inclusive" do
      it "is greater than or equal to the start value and less than or equal to the end value" do
        expect(subject.convert_number_ranges(foo: 1..3)).to eq(foo: { greater_than_or_equal_to: 1, less_than_or_equal_to: 3 })
        expect(subject.convert_number_ranges(foo: 1.1..3.3)).to eq(foo: { greater_than_or_equal_to: 1.1, less_than_or_equal_to: 3.3 })
      end
    end

    context "exclusive" do
      it "is greater than or equal to the start value and less than the end value" do
        expect(subject.convert_number_ranges(foo: 1...3)).to eq(foo: { greater_than_or_equal_to: 1, less_than: 3 })
        expect(subject.convert_number_ranges(foo: 1.1...3.3)).to eq(foo: { greater_than_or_equal_to: 1.1, less_than: 3.3 })
      end
    end

    context "non ranges" do
      it "preserves them" do
        expect(subject.convert_number_ranges(foo: "A")).to eq(foo: "A")
        expect(subject.convert_number_ranges(bar: 9)).to eq(bar: 9)
      end
    end

    context "date/time ranges" do
      let(:start_time) { 3.days.ago }
      let(:end_time) { 3.days.from_now }

      let(:start_date) { start_time.to_date }
      let(:end_date) { end_time.to_date }

      it "preserves them" do
        expect(subject.convert_number_ranges(foo: start_time..end_time)).to eq(foo: start_time..end_time)
        expect(subject.convert_number_ranges(foo: start_date..end_date)).to eq(foo: start_date..end_date)
      end
    end
  end

  describe ".convert_ranges" do
    let(:start_time) { 3.days.ago }
    let(:end_time) { 3.days.from_now }

    it "converts number and time ranges" do
      expected = {
        foo: { greater_than_or_equal_to: 1, less_than_or_equal_to: 3 },
        bar: { before: end_time, after: start_time }
      }
      expect(subject.convert_ranges(foo: 1..3, bar: start_time..end_time)).to eq(expected)
    end
  end
end
