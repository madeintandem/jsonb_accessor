# Changelog
## [Unreleased]

## [1.3.4] - 2022-02-02
### Fixed

- Bug fix: Raised ActiveModel::MissingAttributeError when model was initialized without the jsonb_accessor field [#145](https://github.com/madeintandem/jsonb_accessor/issues/145)

## [1.3.3] - 2022-01-29
### Fixed

- Bug fix: DateTime objects are now correctly written without timezone
information [#137](https://github.com/madeintandem/jsonb_accessor/pull/137).
Thanks @caiohsramos
