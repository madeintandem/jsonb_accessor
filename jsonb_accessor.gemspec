# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jsonb_accessor/version"

Gem::Specification.new do |spec|
  spec.name                  = "jsonb_accessor"
  spec.version               = JsonbAccessor::VERSION
  spec.authors               = ["Michael Crismali", "Joe Hirn", "Jason Haruska"]
  spec.email                 = ["michael.crismali@gmail.com", "joe@devmynd.com", "jason@haruska.com"]

  spec.summary               = %q{Adds typed jsonb backed fields to your ActiveRecord models.}
  spec.description           = %q{Adds typed jsonb backed fields to your ActiveRecord models.}
  spec.homepage              = "https://github.com/devmynd/jsonb_accessor"
  spec.license               = "MIT"
  spec.required_ruby_version = "~> 2.0"

  spec.files                 = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) || f.match(%r{png\z}) }
  spec.bindir                = "exe"
  spec.executables           = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths         = ["lib"]

  spec.add_dependency "activerecord", ">= 5.0"
  spec.add_dependency "pg", ">= 0.18.1"

  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "database_cleaner", "~> 1.5.3"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-doc"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "rubocop", "~> 0.31"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "standalone_migrations"
end
