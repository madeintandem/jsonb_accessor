# frozen_string_literal: true

module JsonbAccessor::Adapters::BaseAdapter
  module_function

  ATTRIBUTE_TYPE = :json

  def apply(_model, _attribute); end
end
