# Changelog

## Release Candidate - 2026-07-31

### Added

- Responsive GlowBook authentication, customer, employee, admin and booking UI flows.
- Shared GlowBook design system, reusable widgets and responsive helpers.
- Backend contract alignment for authentication, catalog, appointment, waitlist, dashboard, notification and profile flows.
- Vercel deployment configuration for Flutter Web.
- GitHub Actions workflow for format, analyze, test and web build.
- Android and iOS release preparation documentation.

### Changed

- Android application id and namespace prepared as `com.glowbook.app`.
- Flutter Web metadata and manifest updated for GlowBook.
- API base URL is configured through `--dart-define=API_BASE_URL`.

### Known Limitations

- Android release signing keystore is not committed and must be configured outside Git.
- iOS release build requires macOS, Xcode and Apple signing.
- Some reporting/analytics metrics are not implemented because backend aggregate endpoints are not available.
- Local Windows + OneDrive environment blocks Flutter symlink/ephemeral cleanup unless Developer Mode is enabled or the project is moved outside OneDrive.
