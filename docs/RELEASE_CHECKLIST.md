# GlowBook Flutter Release Checklist

## Repository

- [x] `git status` checked.
- [x] Branch checked: `main`.
- [x] Remote checked: `origin https://github.com/eyluldurmaz9-dev/glowbook-flutter.git`.
- [x] Recent commits checked.
- [x] Untracked files checked before release commit.
- [x] Merge conflict entries checked.
- [x] Build/cache output tracking checked.
- [x] Push state checked.

## Security

- [x] `.env` and signing files are ignored.
- [x] `.env.example` contains placeholders only.
- [x] API base URL is passed through `--dart-define=API_BASE_URL`.
- [x] No real JWT, SMS, database or signing credential was added.
- [x] Debug token logging was checked by pattern search.

## Web

- [x] `vercel.json` added.
- [x] SPA rewrite to `index.html` configured.
- [x] Flutter base href uses build-time `--base-href=/`.
- [x] Web manifest and page title use GlowBook branding.

## Android

- [x] App name set to `GlowBook`.
- [x] `applicationId` set to `com.glowbook.app`.
- [x] Internet permission present.
- [x] Release signing documented.
- [ ] Real release keystore configured outside Git.
- [ ] Launcher icon replaced with final brand icon.
- [ ] Release APK/AAB validated on a clean non-OneDrive or CI environment.

## iOS

- [x] Display name set to `GlowBook`.
- [x] Signing requirements documented.
- [ ] Bundle identifier confirmed in Xcode.
- [ ] App Store signing validated on macOS.
- [ ] Real device or TestFlight validation completed.

## Validation

- [x] `dart format --set-exit-if-changed .` passed.
- [ ] `flutter analyze` blocked locally by Windows/OneDrive symlink cleanup issue.
- [ ] `flutter test` blocked locally by Windows/OneDrive symlink cleanup issue.
- [ ] `flutter build web --release` blocked locally by Windows/OneDrive symlink cleanup issue after clean.
