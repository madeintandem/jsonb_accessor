# frozen_string_literal: true

require "spec_helper"

RSpec.describe JsonbAccessor::Adapters::PostgresqlAdapter do
  it_behaves_like "a model with query methods"
  it_behaves_like "a model with attribute query methods"
end
