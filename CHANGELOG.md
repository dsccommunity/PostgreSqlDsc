# Changelog for PostgreSqlDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added PostgreSqlInstall resource
  - Install Postgres with specified features
- Added PostgreSqlScript resource
  - Run T-SQL Scripts against Postgres
- Added PostgreSqlDatabase resource
  - Add and remove database in PostgresSql

### Changed

- Removed CreateDatabase from PostgreSqlScript

### Removed

### Fixed

- Fixed issue with Invoke-Command returning errors during test and set.
