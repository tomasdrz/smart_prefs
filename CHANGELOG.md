# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-10-28

### Fixed

- Corrected README

## [0.1.0] - 2025-10-28

### Added

- Initial release of the smart_prefs package
- Support for three storage types: local, remote, and volatile
- Type-safe enum-based API for defining preferences
- Configurable logging system with `PrefsLogger`
- Automatic retry mechanism for remote preference loading (configurable max retries)
- **Connectivity-aware retry**: Check network status before retrying remote loads
- **Remote load callback**: Get notified when remote preferences finish loading
- **Manual reload method**: `Prefs.reloadRemotePreferences()` for on-demand loading
- In-memory caching for fast access
- Extension methods for convenient preference access (`get`, `set`, `clear`)
- Abstract `RemotePrefs` interface for custom backend implementations
- Robust error handling without throwing uncaught exceptions
- Comprehensive documentation including REMOTE_SETUP.md guide
- 100% test coverage (39 tests passing)

### Features

- **Local Storage**: Uses SharedPreferences for persistent local storage
- **Remote Storage**: Extensible backend support (implement `RemotePrefs`)
  - Firebase Firestore example
  - Supabase/PostgreSQL example
  - REST API example
  - SQLite offline-first pattern documentation
- **Volatile Storage**: Fast in-memory storage for session data
- **Type Safety**: Generic types with compile-time checking
- **Configurable Logging**: Custom logger support with 4 log levels
- **Intelligent Retry Logic**:
  - Automatic retries with configurable limits
  - Connectivity checking to avoid offline retries
  - Manual trigger for immediate reload
- **Separation of Concerns**: Clean architecture with dedicated files for logging, callbacks, and core logic

### Supported Data Types

- `String`
- `bool`
- `int`
- `double`
- `List<String>`

### Documentation

- README with complete usage examples
- REMOTE_SETUP.md with database schemas and implementation guides
- API documentation for all public interfaces
- **Complete example**:
  - `example/main.dart`: Basic usage with mock backend
  - Includes commented SQLite offline-first pattern template (450+ lines)

---

## [Unreleased]

### Planned

- Batch operations for setting multiple preferences
- Stream-based change notifications (watch API)
- Value validation framework
- Schema migration system
- Secure storage option for sensitive data
- JSON serialization for complex objects
