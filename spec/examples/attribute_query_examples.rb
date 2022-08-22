# frozen_string_literal: true

RSpec.shared_examples "a model with attribute query methods" do
  describe "#<jsonb_attribute>_where" do
    let(:klass) do
      build_class(
        title: [:string, { store_key: :t }],
        rank: [:integer, { store_key: :r }],
        made_at: [:datetime, { store_key: :ma }]
      )
    end
    let(:title) { "title" }
    let!(:matching_record) { klass.create!(title: title, rank: 4, made_at: Time.current) }
    let!(:ignored_record) { klass.create!(title: "ignored", rank: 3, made_at: 3.years.ago) }
    let!(:blank_record) { klass.create! }
    subject { klass.all }

    it "is records matching the criteria" do
      query = subject.options_where(
        title: title,
        rank: { greater_than: 3, less_than: 7 },
        made_at: { before: 2.days.from_now, after: 2.days.ago }
      )
      expect(query).to exist
      expect(query).to eq([matching_record])
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          jsonb_accessor :options, other_title: [:string, { store_key: :ot }]
        end
      end
      subject { subklass.all }

      it "is records matching the criteria on a subclass" do
        query = subject.options_where(
          title: title,
          rank: { greater_than: 3, less_than: 7 },
          made_at: { before: 2.days.from_now, after: 2.days.ago }
        )
        expect(query).to exist
        expect(query.pluck(:id)).to eq([matching_record.id])
      end
    end
  end

  describe "#<jsonb_attribute>_where_not" do
    let(:klass) do
      build_class(
        title: [:string, { store_key: :t }],
        rank: [:integer, { store_key: :r }],
        made_at: [:datetime, { store_key: :ma }]
      )
    end
    let(:title) { "title" }
    let!(:matching_record) { klass.create!(title: "foo", rank: 4, made_at: Time.current) }
    let!(:ignored_record) { klass.create!(title: title, rank: 3, made_at: 3.years.ago) }
    let!(:blank_record) { klass.create! }
    subject { klass.all }

    it "excludes records matching the criteria" do
      query = subject.options_where_not(
        title: title,
        rank: { greater_than: 5 },
        made_at: { before: 1.year.ago }
      )
      expect(query).to exist
      expect(query).to eq([matching_record])
    end

    context "inheritance" do
      let(:subklass) do
        Class.new(klass) do
          self.table_name = "products"
          jsonb_accessor :options, other_title: [:string, { store_key: :ot }]
        end
      end
      subject { subklass.all }

      it "excludes records matching the criteria on a subclass" do
        query = subject.options_where_not(
          title: title,
          rank: { greater_than: 5 },
          made_at: { before: 1.year.ago }
        )
        expect(query).to exist
        expect(query.pluck(:id)).to eq([matching_record.id])
      end
    end
  end

  describe "#<jsonb_attribute_order>" do
    context "field name only" do
      let(:klass) { build_class(title: :string) }
      let!(:instance_1) { klass.create!(title: "B") }
      let!(:instance_2) { klass.create!(title: "C") }
      let!(:instance_3) { klass.create!(title: "A") }
      let(:ordered_intances) { [instance_3, instance_1, instance_2] }

      it "orders the values" do
        expect(klass.all.options_order(:title)).to eq(ordered_intances)
      end
    end

    context "hash argument" do
      let(:klass) { build_class(title: :string) }
      let!(:instance_1) { klass.create!(title: "B") }
      let!(:instance_2) { klass.create!(title: "C") }
      let!(:instance_3) { klass.create!(title: "A") }
      let(:ordered_intances) { [instance_2, instance_1, instance_3] }

      it "orders the values" do
        expect(klass.all.options_order(title: :desc)).to eq(ordered_intances)
      end
    end

    context "field names and a hash argument" do
      let(:klass) { build_class(title: :string, rank: :integer, name: :string) }
      let!(:instance_1) { klass.create!(title: "B", rank: 99, name: "A") }
      let!(:instance_2) { klass.create!(title: "A", rank: 100, name: "A") }
      let!(:instance_3) { klass.create!(title: "B", rank: 99, name: "B") }
      let!(:instance_4) { klass.create!(title: "B", rank: 100, name: "A") }
      let(:ordered_intances) { [instance_2, instance_4, instance_1, instance_3] }
      let(:filtered_and_ordered_intances) { [instance_2, instance_4, instance_1] }

      it "orders the values" do
        expect(klass.all.options_order(:title, rank: :desc, name: :asc)).to eq(ordered_intances)
        expect(klass.all.options_where(name: "A").options_order(:title, rank: :desc, name: :asc)).to eq(filtered_and_ordered_intances)
      end
    end

    context "store keys" do
      let(:klass) { build_class(title: [:string, { store_key: :t }]) }
      let!(:instance_1) { klass.create!(title: "B") }
      let!(:instance_2) { klass.create!(title: "C") }
      let!(:instance_3) { klass.create!(title: "A") }
      let(:ordered_intances) { [instance_3, instance_1, instance_2] }

      it "orders the values while accounting for store keys" do
        expect(klass.all.options_order(:title)).to eq(ordered_intances)
      end
    end
  end
end
