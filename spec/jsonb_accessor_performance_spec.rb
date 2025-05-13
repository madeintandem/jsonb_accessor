# frozen_string_literal: true

require "benchmark"
require "spec_helper"

RSpec.describe "Jsonb Accessor Performace" do
  context "initializing objects from the database" do
    before do
      1000.times do
        Product.create(
          string_type: "static string",
          integer_type: (1..60_000).to_a.sample,
          boolean_type: [true, false].sample,
          float_type: rand,
          time_type: Time.now,
          date_type: Date.today
        )
      end
    end

    it "is of reasonable performance against non-jsonb records" do
      static_time = Benchmark.realtime { StaticProduct.all.to_a }
      jsonb_time = Benchmark.realtime { Product.all.to_a }
      # it shouldn't even be 0.1 seconds slower to fetch and instantiate 1000 records
      expect((static_time - jsonb_time).abs).to be < 0.1
    end
  end
end
