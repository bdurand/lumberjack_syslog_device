# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.0.1

### Fixed

- Fixed `close` raising a `NoMethodError` due to referencing an unset lock and connection.
- Fixed the syslog connection being closed and reopened on every write when using the default facility. The facility now defaults to `Syslog::LOG_USER` so the connection reuse check matches what syslog reports.
- A nil progname now opens syslog with a nil ident so syslog defaults to the program name instead of an empty string.
- Unmapped severity values are now logged as `Syslog::LOG_ALERT` instead of raising a `TypeError`.
- The log mask is now reset when reusing a connection opened elsewhere with a more restrictive mask.

## 2.0.0

### Added

- Lumberjack 2 support.

### Changed

- Updated default template to `{{message}} {{attributes}}`. Unit of work is no longer supported in Lumberjack 2.
- Updated attribute formatting to use tag formatting specified in the `:tag_format` option rather than hardcoding the format.

### Removed

- Support for Ruby < 2.7.

## 1.1.1

### Changed

- Always cast values to strings before logging to syslog (thanks @eremeyev).

## 1.1.0

### Added

- Add support for lumberjack 1.1 tags.

## 1.0.0

### Added

- Initial release.