# GlowBook Known Limitations

Date: 2026-07-31

## Backend Contract Gaps

- There is no separate service category entity or category CRUD endpoint.
  Current catalog structure is service based.
- There is no global admin appointment list endpoint with pagination, sorting or
  filtering. Admin UI uses employee-scoped schedule endpoints.
- There is no package hard-delete endpoint. Package management supports create
  and update only.
- There is no admin notification management endpoint. Customer notifications
  can be listed and marked read by owner/admin/employee authorization.
- There is no revenue, dashboard metrics, reporting or analytics endpoint.
  Flutter does not show fabricated revenue or performance data.
- Pagination and sorting parameters are not defined for current list endpoints.
  Flutter does not send invented pagination or sorting query parameters.

## Security And Operations

- SMS delivery requires real provider credentials. Backend must use environment
  configuration and must not report fake SMS success when credentials are
  missing.
- CORS policy should be explicitly configured per deployment origin before
  public production use.
- Refresh token storage is backend-owned; Flutter stores tokens in secure
  storage and clears them when refresh fails.
- Admin and employee management endpoints currently overlap in some backend
  method-level rules. The UI enforces admin-only admin panel access, but backend
  authorization remains the final source of truth.

## Date And Time

- Backend uses `LocalDate` and `LocalTime`; no explicit time zone is included in
  appointment DTOs.
- Flutter formats dates as ISO `yyyy-MM-dd` and normalizes times to `HH:mm`.
  Cross-time-zone deployments should define a business time zone explicitly.

## Test Coverage Notes

- Added targeted backend tests for authorization support and employee admin role
  escalation.
- Added Flutter tests for safe API error mapping.
- Broader controller integration tests for every endpoint should be added once a
  stable test fixture dataset is agreed.
