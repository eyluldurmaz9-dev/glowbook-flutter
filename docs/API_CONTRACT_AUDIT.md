# GlowBook API Contract Audit

Date: 2026-07-31

## Scope

Audited `glowbook-flutter` against the Spring Boot API in `glowbook-backend`.
`glowbook-visualAssentManager-ui` was treated only as the UI reference and not
as an API source of truth.

## Endpoint Coverage

Flutter endpoint | Backend status | Notes
--- | --- | ---
`POST /api/auth/register` | Exists | Customer register DTO matches.
`POST /api/auth/login` | Exists | Fixed backend role escalation for employee login.
`POST /api/auth/refresh` | Exists | Flutter refresh flow uses `refreshToken`.
`GET /api/admin/customers` | Exists | Admin/employee only.
`GET /api/customers/{customerId}` | Exists | Customer owner check enforced.
`PUT /api/customers/{customerId}` | Exists | DTO requires password; Flutter profile sends it intentionally.
`GET /api/customers/{customerId}/packages` | Exists | Owner check enforced.
`POST /api/customers/{customerId}/packages/{packageId}` | Exists | Owner check enforced.
`GET /api/admin/employees` | Exists | Admin/employee security at backend.
`POST /api/admin/employees` | Exists | Admin only by controller class rule.
`PUT /api/admin/employees/{employeeId}` | Exists | DTO requires password.
`DELETE /api/admin/employees/{employeeId}` | Exists | Deactivates, does not hard delete.
`POST /api/admin/employees/services` | Exists | Assign service to employee.
`GET /api/admin/employees/services/{serviceId}` | Exists | Used for booking employee selection.
`POST /api/admin/employees/leaves` | Exists | Admin only in backend controller.
`GET /api/admin/employees/{employeeId}/leaves` | Exists | Admin only in backend controller.
`GET /api/catalog/services` | Exists | Returns active services.
`GET /api/catalog/services/{serviceId}/options` | Exists | Returns active price options.
`GET /api/catalog/services/{serviceId}/packages` | Exists | Returns active packages.
`POST /api/admin/services` | Exists | Admin/employee by method rule.
`PUT /api/admin/services/{serviceId}` | Exists | Admin/employee by method rule.
`DELETE /api/admin/services/{serviceId}` | Exists | Deactivates service.
`POST /api/admin/services/{serviceId}/options` | Exists | Price management.
`PUT /api/admin/options/{optionId}` | Exists | Price management.
`POST /api/admin/services/{serviceId}/packages` | Exists | Package create.
`PUT /api/admin/packages/{packageId}` | Exists | Package update.
`GET /api/appointments/available-slots` | Exists | Backend algorithm is source of truth.
`POST /api/appointments` | Exists | Public/guest booking supported.
`GET /api/appointments/{appointmentId}` | Exists | Fixed owner/admin/employee access check.
`GET /api/appointments/customer/{customerId}/upcoming` | Exists | Fixed owner/admin/employee access check.
`GET /api/appointments/customer/{customerId}/past` | Exists | Fixed owner/admin/employee access check.
`GET /api/appointments/employee/{employeeId}` | Exists | Admin/employee only.
`PATCH /api/appointments/{appointmentId}/approve` | Exists | Status enum: `PENDING`, `APPROVED`, `COMPLETED`, `CANCELLED`.
`PATCH /api/appointments/{appointmentId}/complete` | Exists | Status enum aligned.
`PATCH /api/appointments/{appointmentId}/cancel` | Exists | Fixed owner/admin/employee access check.
`PATCH /api/appointments/{appointmentId}/time` | Exists | Admin/employee only.
`GET /api/notifications/customer/{customerId}` | Exists | Fixed owner/admin/employee access check.
`GET /api/notifications/customer/{customerId}/unread` | Exists | Fixed owner/admin/employee access check.
`PATCH /api/notifications/{notificationId}/read` | Exists | Fixed notification owner/admin/employee access check.
`GET /api/catalog/working-hours` | Exists | Public catalog data.
`POST /api/admin/working-hours` | Exists | Admin/employee by method rule.
`PUT /api/admin/working-hours/{workingHourId}` | Exists | Admin/employee by method rule.
`GET /api/catalog/holidays` | Exists | Requires `startDate`, `endDate`.
`POST /api/admin/holidays` | Exists | Admin/employee by method rule.
`POST /api/waiting-list` | Exists | Guest and customer waitlist supported.
`GET /api/waiting-list` | Exists | Admin/employee only.
`GET /api/waiting-list/customer/{customerId}` | Exists | Fixed owner/admin/employee access check.
`PATCH /api/waiting-list/{waitingListId}/cancel` | Exists | Fixed owner/admin/employee access check.
`PATCH /api/waiting-list/{waitingListId}/converted` | Exists | Admin/employee only.

## DTO And Type Findings

- Dates use ISO `yyyy-MM-dd`; Flutter centralizes date formatting with
  `BookingDateUtils.formatDate`.
- Times are backend `LocalTime`; Flutter normalizes to `HH:mm` for display.
- Appointment statuses match backend enum: `PENDING`, `APPROVED`, `COMPLETED`,
  `CANCELLED`.
- Waiting list statuses are backend-owned; Flutter does not invent extra states.
- Service category CRUD is not a separate backend concept. GlowBook currently
  models catalog structure as service -> option/package.
- Package delete is not exposed by backend; Flutter does not hard-delete
  packages.
- Admin appointment listing is not global; backend exposes employee-scoped
  schedules only.

## Security Fixes Applied

- Prevented normal employees from requesting an `ADMIN` token during login.
- Added shared customer resource authorization support in backend.
- Enforced owner/admin/employee access on customer appointment lists.
- Enforced owner/admin/employee access on appointment detail and cancellation.
- Enforced owner/admin/employee access on notification lists and read updates.
- Enforced owner/admin/employee access on customer waiting list reads and
  cancellation.
- Added Flutter API error mapping for 401, 403, 409 and validation responses.

## Backend Endpoints Not Yet Used Critically By Flutter

- `POST /api/admin/employees/services` for assigning services to staff.
- `POST /api/admin/employees/leaves` and
  `GET /api/admin/employees/{employeeId}/leaves` for staff leave management.
- `PATCH /api/appointments/{appointmentId}/time` for rescheduling.
- `GET /api/waiting-list` and `PATCH /api/waiting-list/{id}/converted` for full
  waitlist operations.

## Verification

The audit requires backend and Flutter test suites to be run after changes.
Command results are reported in the task summary.
