module JsonbAccessor
  module Helpers
    module_function

    def active_record_default_timezone
      ActiveRecord.try(:default_timezone) || ActiveRecord::Base.default_timezone
    end
  end
end
