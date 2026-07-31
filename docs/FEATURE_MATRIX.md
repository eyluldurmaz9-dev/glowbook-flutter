# GlowBook Feature Matrix

Status values:

- Completed
- Partially completed
- Blocked by backend
- Requires external credential
- Requires real-device validation
- Not implemented

| Area | Feature | Status | Notes |
| --- | --- | --- | --- |
| Auth | Splash | Completed | Responsive Flutter screen exists. |
| Auth | Welcome / onboarding | Completed | GlowBook branded landing/welcome flow exists. |
| Auth | Customer login | Completed | Uses backend auth and secure token storage. |
| Auth | Customer register | Completed | Uses backend registration endpoint. |
| Auth | Employee login | Completed | Role-aware login supported. |
| Auth | Guest continue | Completed | Guest booking/customer discovery path supported where backend allows public appointment creation. |
| Auth | Forgot password | Blocked by backend | Backend password reset endpoint is not available. |
| Auth | JWT access token | Completed | Dio client attaches bearer token. |
| Auth | Refresh token | Completed | Refresh flow integrated with backend contract. |
| Auth | Logout | Partially completed | Local token cleanup exists; backend revoke/logout endpoint is limited. |
| Customer | Home dashboard | Completed | Uses real service/package/dashboard data where available. |
| Customer | Services list | Completed | Uses Service API. |
| Customer | Service detail | Completed | Uses real model mapping and safe fallbacks. |
| Customer | Packages list | Completed | Uses Package API. |
| Customer | Package detail | Completed | Uses real package fields. |
| Customer | Search | Completed | Local UI search available. |
| Customer | Backend filtering | Blocked by backend | No complete filter/pagination contract for all catalog views. |
| Customer | Favorites | Blocked by backend | No verified favorite API/local persistence contract. |
| Booking | Multi-step appointment flow | Completed | Backend availability remains source of truth. |
| Booking | Availability slots | Completed | Uses backend slot responses. |
| Booking | Waitlist | Completed | Connected where backend endpoint exists. |
| Booking | Timezone/date helpers | Completed | Central helpers/tests exist. |
| Customer dashboard | Upcoming appointments | Completed | Real appointment data split by date/status. |
| Customer dashboard | Past appointments | Completed | Real appointment data split by date/status. |
| Customer dashboard | Appointment cancel | Completed | Confirmation and API handling included. |
| Customer dashboard | Reschedule/update | Partially completed | UI only enables operations supported by backend contract. |
| Customer dashboard | My packages | Completed | Uses customer package API. |
| Customer dashboard | Package usage history | Blocked by backend | Detailed history endpoint is limited. |
| Customer dashboard | Notifications | Completed | Uses Notification API. |
| Customer dashboard | Profile view/update | Completed | Uses profile/customer APIs. |
| Customer dashboard | Password change | Partially completed | Depends on backend-supported profile update behavior. |
| Employee | Staff dashboard | Completed | Role guard and schedule views exist. |
| Employee | Daily appointments | Completed | Uses backend appointment data. |
| Employee | Weekly calendar | Completed | Responsive staff calendar exists. |
| Employee | Appointment status update | Completed | Uses backend status enum contract. |
| Employee | Working hours | Completed | Uses schedule endpoints where available. |
| Employee | Availability update | Partially completed | Limited by backend schedule contract. |
| Employee | Notifications | Completed | Uses notification flow where authorized. |
| Admin | Admin dashboard | Completed | Web-first responsive layout exists. |
| Admin | Service CRUD | Completed | Uses backend admin APIs. |
| Admin | Service category CRUD | Not implemented | Backend service category endpoint is not established. |
| Admin | Price management | Partially completed | Service option/package pricing can be managed; dedicated pricing module unavailable. |
| Admin | Package CRUD | Completed | Uses backend package APIs. |
| Admin | Employee management | Completed | Uses backend employee APIs. |
| Admin | Working hours / holidays | Completed | Uses schedule/admin endpoints where available. |
| Admin | Appointment management | Completed | Uses appointment APIs. |
| Admin | Customer list | Partially completed | Depends on backend authorization and customer endpoints. |
| Admin | Notification management | Blocked by backend | Dedicated admin notification management is limited. |
| Admin | Statistics | Blocked by backend | Aggregate metrics endpoints are not available. |
| Platform | Flutter Web deployment | Completed | Vercel config and SPA rewrite added. |
| Platform | Android release | Requires real-device validation | Config prepared; signing and device validation remain. |
| Platform | iOS release | Requires real-device validation | Requires macOS, Xcode and signing. |
| Integration | SMS | Requires external credential | Backend fallback exists; real provider credentials not committed. |
