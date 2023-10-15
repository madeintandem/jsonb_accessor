# frozen_string_literal: true

module JsonbAccessor
  VERSION = "1.4"

  def self.enum_support?
    # From AR 7.1 on, enums require a database column.
    Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("7.1")
  end
end
