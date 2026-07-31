# Manual Validation Checklist

## Flutter Web

- [ ] Deploy to Vercel with `API_BASE_URL` environment variable.
- [ ] Open direct deep links such as `/login`, `/services`, `/appointment`, `/customer/dashboard`, `/admin`.
- [ ] Verify browser back/forward behavior.
- [ ] Test login/register/token refresh/logout flows.
- [ ] Test customer appointment booking, waitlist and cancellation.
- [ ] Test employee and admin route guards.
- [ ] Check responsive layouts at small phone, standard phone, tablet, 1366px and wide desktop widths.
- [ ] Run keyboard-only navigation on auth and booking flows.
- [ ] Run screen reader smoke check for forms, cards and navigation.

## Android

- [ ] Enable clean Flutter build environment.
- [ ] Configure release keystore outside Git.
- [ ] Build APK and AAB.
- [ ] Install on a real Android device.
- [ ] Verify HTTPS API connectivity.
- [ ] Verify soft keyboard behavior on auth, profile and booking forms.
- [ ] Verify notification/profile/dashboard navigation.
- [ ] Confirm final launcher icon and app label.

## iOS

- [ ] Open project on macOS with Xcode.
- [ ] Set Team, bundle identifier and signing profile.
- [ ] Run `flutter build ios --release --no-codesign`.
- [ ] Run archive/TestFlight build with signing.
- [ ] Validate login, booking and dashboards on simulator and real device.
- [ ] Confirm privacy strings if new native permissions are added.

## Backend

- [ ] Provision real MySQL database.
- [ ] Apply production schema/migrations.
- [ ] Start backend with `SPRING_PROFILES_ACTIVE=prod`.
- [ ] Verify `/actuator/health` and `/health`.
- [ ] Verify CORS allows only expected Flutter Web domains.
- [ ] Verify auth, refresh and role-protected endpoints.
- [ ] Verify appointment availability and conflict behavior with concurrent requests.
- [ ] Configure real SMS provider credentials outside Git.
- [ ] Verify scheduler reminders do not duplicate sends.

## Security

- [ ] Confirm no `.env`, keystore, p12, pem, private key or production credential is committed.
- [ ] Rotate any credential that was ever shared outside a secret manager.
- [ ] Confirm logs do not include JWT, refresh token, password, full phone number or SMS content.
- [ ] Confirm production API URL uses HTTPS.
