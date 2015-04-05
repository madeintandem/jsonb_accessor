require "active_record"

require "active_record/connection_adapters/postgresql_adapter"

require "jsonb_accessor/version"
require "jsonb_accessor/type_helper"
require "jsonb_accessor/nested_base"
require "jsonb_accessor/class_builder"
require "jsonb_accessor/macro"

module JsonbAccessor
  extend ActiveSupport::Concern
  include Macro
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, JsonbAccessor)
end
