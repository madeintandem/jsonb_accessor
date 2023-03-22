# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jsonb_accessor/version"

is_java = RUBY_PLATFORM == "java"

Gem::Specification.new do |spec|
  spec.name                  = "jsonb_accessor"
  spec.version               = JsonbAccessor::VERSION
  spec.authors               = ["Michael Crismali", "Joe Hirn", "Jason Haruska"]
  spec.email                 = ["michael@crismali.com", "joe@devmynd.com", "jason@haruska.com"]
  spec.platform              = "java" if is_java

  spec.summary               = "Adds typed jsonb backed fields to your ActiveRecord models."
  spec.description           = "Adds typed jsonb backed fields to your ActiveRecord models."
  spec.homepage              = "https://github.com/devmynd/jsonb_accessor"
  spec.license               = "MIT"
  spec.required_ruby_version = ">= 2"

  spec.files                 = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) || f.match(/png\z/) }
  spec.bindir                = "exe"
  spec.executables           = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths         = ["lib"]

  spec.add_dependency "activerecord", ">= 5.0"
  spec.add_dependency "activesupport", ">= 5.0"
  if is_java
    spec.add_dependency "activerecord-jdbcpostgresql-adapter", ">= 50.0"
  else
    spec.add_dependency "pg", ">= 0.18.1"
  end

  spec.add_development_dependency "appraisal", "~> 2.2.0"
  spec.add_development_dependency "awesome_print", "~> 1.9.2"
  spec.add_development_dependency "database_cleaner", "~> 1.6.0"
  spec.add_development_dependency "pry", "~> 0.14.2"
  spec.add_development_dependency "pry-doc", "~> 1.4.0"
  spec.add_development_dependency "pry-nav", "~> 1.0.0"
  spec.add_development_dependency "psych", "~> 3"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.6.0"
  spec.add_development_dependency "rubocop", "~> 1"
end
