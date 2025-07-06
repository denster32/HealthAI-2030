# iOS 26 API Audit Report

This report documents the results of an audit of SomnaSync's codebase for compatibility with iOS 26. The review focused on `Managers/`, `Utilities/`, and `Views/` modules.

## Summary of Updates

- Replaced deprecated `NavigationView` with `NavigationStack` across all SwiftUI views.
- Implemented `AppHostingController` to manage status bar style, removing the deprecated `UIApplication.shared.statusBarStyle` usage.
- Updated `SceneDelegate` to use the new hosting controller.

## Recommendations

- Review remaining UIKit-based APIs for modern SwiftUI replacements.
- Consider adopting Swift Concurrency features (e.g., `Clock` timers) where `Timer` is still in use.
- Investigate `UIBackgroundTaskIdentifier` usage within `AppleWatchManager` and migrate to `BGTaskScheduler` if appropriate.

## Further Discussion

The replacement of timers and background task handling may introduce breaking changes. An issue should be opened to coordinate these updates with the team.

