# frozen_string_literal: true

require "active_record"

require "active_record/connection_adapters/postgresql_adapter"

require "jsonb_accessor/version"
require "jsonb_accessor/helpers"
require "jsonb_accessor/macro"
require "jsonb_accessor/query_helper"
require "jsonb_accessor/query_builder"
require "jsonb_accessor/attribute_query_methods"

module JsonbAccessor
  extend ActiveSupport::Concern
  include Macro
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include JsonbAccessor
end
