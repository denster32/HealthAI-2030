# 📊 Test Coverage Report

This report summarizes the current unit test coverage for SomnaSync.

## Covered Modules
- **Analytics** – `test_background_health_analyzer.swift` exercises anomaly counting and model accuracy helpers.
- **Managers** – `test_watch_sync_start_stop.swift` verifies watch sync services.
- **Models** – `test_models.swift` validates `SleepSession` duration, `SleepStage` helpers and audio type names.
- **Utilities** – `test_volume_auto_change.swift` tests volume updates in a mock engine.
- **Audio Generation Engine** – `test_audio_generation.swift` covers sine wave, noise generation, volume scaling and fade logic.

## Coverage Gaps
- **ML Prediction Engine** – no direct tests for `SleepStagePredictor` due to framework dependencies.
- **View Layer** – views and UI components lack tests.
- **Apple Watch Managers** – advanced watch integration paths are untested.
- **App delegate and configuration** – initialization routines are not covered.

Additional unit tests should be added for these areas when environment and tooling allow.
