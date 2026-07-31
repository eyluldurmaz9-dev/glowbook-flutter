# GlowBook Final Technical Audit

Date: 2026-07-31

## Scope

This audit covers:

- Flutter repository: `glowbook-flutter`
- Backend repository: `glowbook-backend` / local folder `glowbook`
- Design reference repository: `glowbook-visualAssentManager-ui`

No new feature development was performed during this audit. No critical or high-priority code fix was applied.

## Commands Run

### Flutter

| Command | Result | Evidence |
| --- | --- | --- |
| `dart format --set-exit-if-changed .` | Passed | 78 files checked, 0 changed. |
| `flutter analyze` | Blocked by local environment | Flutter tool cannot delete `ios/Flutter/ephemeral/Packages/.packages` under Windows/OneDrive. |
| `flutter test` | Blocked by local environment | Same Flutter tool ephemeral/symlink issue. |
| `flutter build web --release --dart-define=API_BASE_URL=https://api.example.com --base-href=/` | Blocked by local environment | Same Flutter tool ephemeral/symlink issue. |
| `flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com` | Blocked by local environment | Same Flutter tool ephemeral/symlink issue. |
| `flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com` | Blocked by local environment | Same Flutter tool ephemeral/symlink issue. |

Comparison with previous reports:

- Previous report recorded `flutter analyze` passing before local `flutter clean`.
- Previous report recorded `flutter test` passing with 48 tests before local `flutter clean`.
- Previous report recorded `flutter build web --release --no-pub` passing before local symlink cleanup issues.
- Current result is unchanged as an environment blocker, not a newly detected Dart/Flutter source error.

### Backend

| Command | Result | Evidence |
| --- | --- | --- |
| `.\mvnw.cmd test` | Passed | 4 tests, 0 failures, 0 errors. |
| `.\mvnw.cmd verify` | Passed | 4 tests passed and boot jar repackaged. |
| Prod smoke test with H2 MySQL mode | Passed | `prod` profile loaded with safe env overrides and 4 tests passed. |

Comparison with previous reports:

- Backend result is consistent with earlier `test`, `verify`, and prod smoke outcomes.
- No regression was observed in the final audit.

## Backend Audit

| Area | Status | Notes |
| --- | --- | --- |
| Entity | Completed | JPA entities exist for customer, employee, appointment, services, packages, notifications, waiting list, schedule and refresh tokens. |
| Repository | Completed | Repository layer exists for core domain entities. |
| Service | Completed | Services exist for auth, appointments, availability, packages, catalog, customer, employee, waiting list, notifications and scheduler support. |
| DTO | Completed | Request/response DTO records exist for public API contracts. |
| Controller | Completed | Controllers exist for auth, catalog, appointment, customer, employee/admin, schedule, waiting list, notification and health. |
| Exception handling | Completed | Global exception handling is present. |
| Security | Completed | Stateless Spring Security config, role checks and secure headers are configured. |
| JWT | Completed | Access token generation/validation and refresh token storage are implemented. |
| Role authorization | Completed | Admin/employee/customer authorization boundaries exist. |
| Appointment | Completed | Appointment create/cancel/status/update paths are present where supported. |
| Availability | Completed | Backend availability remains source of truth. |
| Waiting list | Completed | Waiting list create/cancel/convert paths exist. |
| Notifications | Completed | Notification API and SMS send path exist. |
| Scheduler | Completed | Reminder scheduler exists with cron from env. |
| SMS configuration | Requires external credential | Current fallback logs masked SMS events; real provider credentials are not configured. |
| Database migration | Partially completed | SQL migration directory exists, but Flyway/Liquibase runtime dependency is not wired. |
| Production configuration | Completed with limitations | Env-based DB/JWT/CORS/PORT config exists; real MySQL schema validation was not run. |
| Tests | Partially completed | Tests pass, but coverage is still narrow for controller/security/concurrency scenarios. |

## Flutter Audit

| Area | Status | Notes |
| --- | --- | --- |
| Splash | Completed | Route and screen exist. |
| Welcome | Completed | Responsive branded welcome screen exists. |
| Authentication | Completed | Login/register/role routing and token storage are integrated. |
| Customer home | Completed | Uses backend-backed catalog data. |
| Services | Completed | List and detail routes exist. |
| Packages | Completed | List and detail routes exist. |
| Appointment flow | Completed with limitations | Multi-step flow uses backend availability; real device/browser build validation is pending. |
| Customer dashboard | Completed | Appointments, packages, notifications and profile entry points exist. |
| Employee dashboard | Completed | Staff calendar/appointments/notifications/profile flow exists. |
| Admin dashboard | Completed with limitations | CRUD and management screens exist; aggregate metrics remain backend-limited. |
| Notifications | Completed | Notification list and mark-read flow exist. |
| Profile | Completed | View/update flow exists. |
| Role guards | Completed | Router/controller role checks exist. |
| API integration | Completed | Dio client, refresh handling and repository/service layer exist. |
| State management | Completed | Riverpod providers and controllers are used. |
| Responsive UI | Completed with limitations | LayoutBuilder/responsive helpers are present; final device/browser QA remains manual. |
| Accessibility | Partially completed | Semantics/tooltips/focus states exist in shared widgets; full screen reader audit not performed. |
| Android build | Requires real-device validation | Local build blocked by Flutter tool symlink issue. |
| Flutter Web build | Requires clean environment validation | Previous web build passed; current local build blocked by symlink issue. |
| iOS configuration | Requires real-device validation | Info.plist exists; actual build requires macOS/Xcode/signing. |

## Design Reference Differences

- Visual Asset Manager prototype contains richer marketing/landing sections than Flutter currently exposes in full depth.
- Some design-only metrics such as revenue, occupancy, employee performance and popularity charts remain absent because backend aggregate endpoints are unavailable.
- Design references include salon/location/map style areas; backend has no salon/location model.
- Employee rating/image fields in the design are not backed by backend DTOs.
- Some service-category concepts from the design remain mapped through existing service data because a service-category CRUD contract is not established.

## Backend Unsupported UI Functions

- Forgot password/reset flow.
- Dedicated favorites API.
- Full service category CRUD contract.
- Aggregate admin statistics.
- Dedicated admin notification management.
- Detailed package usage history.
- Backend logout/revoke endpoint beyond current refresh-token behavior/local logout assumptions.

## GitHub and Deployment

| Area | Status | Notes |
| --- | --- | --- |
| Repository separation | Completed | Flutter, backend and design reference repos remain separate. |
| Clean git status | Completed | All three repos were clean before docs were generated. |
| CI workflow | Completed | Flutter and backend workflows exist. |
| README | Completed | Flutter and backend README files exist. |
| Env templates | Completed | `.env.example` files exist with placeholders only. |
| Vercel config | Completed | Flutter `vercel.json` supports SPA rewrite. |
| Backend deployment config | Completed | Railway/Render deployment docs and env config exist. |
| Secret control | Completed with limitations | No real credential file detected; backend README contains only local placeholder examples. |

## Priority Findings

### Release Blocking

- Flutter local verification cannot complete on this Windows/OneDrive workspace because Flutter cannot delete generated iOS/macOS ephemeral symlink/reparse directories. Use CI, enable Windows Developer Mode, or move the repo outside OneDrive and rerun all Flutter checks.
- Real Android release signing and real device validation are not complete.
- Real iOS build/signing requires macOS, Xcode and Apple account configuration.
- Real production MySQL schema validation was not performed.

### Non-Blocking / Medium-Low

- Backend test coverage is functional but narrow.
- Migration strategy should be finalized with Flyway/Liquibase or a documented CI/CD migration step.
- Full accessibility audit with screen readers was not performed.
- Final brand launcher icon still requires confirmation/replacement.
