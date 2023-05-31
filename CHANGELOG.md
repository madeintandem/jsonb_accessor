# Changelog
## [Unreleased]

## [1.3.10] - 2023-05-30
### No changes
A new release was necessary to fix the corrupted 1.3.9 Java release on RubyGems.

## [1.3.9] - 2023-05-30
### No changes
A new release was necessary to fix the corrupted 1.3.8 Java release on RubyGems.

## [1.3.8] - 2023-05-29
### Fixes

- Support for ActiveRecord::Enum. [#163](https://github.com/madeintandem/jsonb_accessor/pull/163)

## [1.3.7] - 2022-12-29

- jruby support. jsonb_accessor now depends on `activerecord-jdbcpostgresql-adapter` instead of `pg` when the RUBY_PLATFORM is java. [#157](https://github.com/madeintandem/jsonb_accessor/pull/157)

## [1.3.6] - 2022-09-23
### Fixed

- Bug fix: Datetime values were not properly deserialized [#155](https://github.com/madeintandem/jsonb_accessor/pull/155)

## [1.3.5] - 2022-07-23
### Fixed

- Bug fix: Attributes defined outside of jsonb_accessor are not written [#149](https://github.com/madeintandem/jsonb_accessor/pull/149)

## [1.3.4] - 2022-02-02
### Fixed

- Bug fix: Raised ActiveModel::MissingAttributeError when model was initialized without the jsonb_accessor field [#145](https://github.com/madeintandem/jsonb_accessor/issues/145)

## [1.3.3] - 2022-01-29
### Fixed

- Bug fix: DateTime objects are now correctly written without timezone
information [#137](https://github.com/madeintandem/jsonb_accessor/pull/137).
Thanks @caiohsramos
