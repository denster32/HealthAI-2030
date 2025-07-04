# Changelog

## [1.0.0] - 2025-07-04
### Added
- Full HealthKit integration via `HealthKitManager` with async/await APIs and unit tests.
- Enhanced `SleepFeatureExtractor` with RMSSD, SDNN, activity count, temperature gradient, and complete feature vector logic.
- `SleepCloudKitManager` sync methods fully implemented and covered by unit tests.
- `DateUtils` utility module for common date operations, with tests.
- Unit tests for `HealthDataEntry` JSON decoding errors and success.
- Comprehensive CI/CD GitHub Actions workflow including SwiftPM and Xcode build/test and code coverage uploads.

### Changed
- `SleepSession` model extended with optional metadata (`interruptions`, `deviceSource`, `userNotes`) and computed properties (`wasoDuration`, `sleepEfficiency`).
- Updated `docs/SleepStageClassifier.md` for Markdown lint compliance and API usage examples.
- Bumped swift-tools-version to 5.7 in `Package.swift` and all module manifests.

### Fixed
- Added error handling around CloudKit and HealthKit calls.
- Refactored duplicate date logic into `DateUtils`.

## Unreleased
- CI/CD enhancements: version bump and changelog creation.
