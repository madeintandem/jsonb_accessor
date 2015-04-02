require "active_record"

require "jsonb_accessor/version"
require "jsonb_accessor/macro"

module JsonbAccessor
  extend ActiveSupport::Concern
  include Macro
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, JsonbAccessor)
end
