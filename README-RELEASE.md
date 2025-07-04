# HealthAI 2030 Release Guide

## Steps to Release

1. **Run validation**
   ```sh
   ./Scripts/validate_release.sh
   ```
   - Ensures test coverage >90% and no unresolved TODOs.

2. **Run release script**
   ```sh
   ./Scripts/release.sh
   ```
   - Runs tests, builds, tags the version, and pushes the tag to origin.

3. **CI/CD**
   - GitHub Actions will build, test, and upload coverage for the new tag.

4. **App Store/TestFlight**
   - For iOS/macOS/tvOS/watchOS, archive and upload via Xcode Organizer as needed.

5. **Update Changelog**
   - Add any last-minute fixes or notes to `CHANGELOG.md`.

## Notes
- Ensure all documentation is up to date before release.
- For major releases, increment the version in `Package.swift` and tag accordingly.
