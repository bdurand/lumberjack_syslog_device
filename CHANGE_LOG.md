# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.0.0

### Added

- Lumberjack 2 support.

### Changed

- Updated default template to `:message :attributes`. Unit of work is no longer supported in Lumberjack 2.
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