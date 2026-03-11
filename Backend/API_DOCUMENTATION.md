# Backend API Documentation

This document is a developer-focused API reference for the `JobFairPortal` backend.

## 1) Quick Facts

- **Framework:** ASP.NET Core (.NET 8)
- **Base URLs (dev):**
  - `http://localhost:5158`
  - `https://localhost:7050`
- **Swagger (dev):** `/swagger`
- **SignalR Hub:** `/hubs/companyRequests`
- **Auth:** JWT Bearer tokens (`Authorization: Bearer <token>`)
- **Primary DB:** PostgreSQL via EF Core

---

## 2) Authentication & Roles

### Supported Roles
- `Admin`
- `Company`
- `Student`

### Role Access by Controller
- `AdminController`: Admin-only (controller-level authorization)
- `CompanyRequestsController`: Admin-only
- `StudentController`: Student-only (except a few `[Authorize]` generic endpoints)
- `CompanyController`: Mixed, but most business operations are Company-only
- `AttendanceController`: mixed (public scan + role-protected actions)
- `SurveyController`: mixed (template/public + company-protected submit/status)
- `AuthController`: login/signup/reset endpoints (public), password change (authorized)

### JWT Notes
- JWT settings live in `appsettings.json` under `Jwt`.
- Backend accepts bearer token in header for REST APIs.
- For SignalR, token can also be passed via `access_token` query for `/hubs/companyRequests`.

---

## 3) Request/Response Conventions

### Common Patterns
- Successful writes generally return `200 OK` with message + payload.
- Validation/business failures return `400 BadRequest`.
- Unauthorized/forbidden return `401/403`.
- Not found returns `404`.

### Core DTOs used frequently
- `LoginDto`: `emailOrRegNo`, `password`, `fcmToken?`
- `StudentRegistrationDto`: `registrationNo`
- `CompanySignupDto` (`multipart/form-data` due to optional logo upload)
- `ProjectAddDto`, `ProjectInviteDto`, `ProjectUpdateDto`
- `CreateJobDto`, `UpdateJobDto`
- `SendInterviewRequestDto`, `SendCompanyInterviewRequestDto`, `RejectInterviewRequestDto`
- `ScheduleInterviewDto`
- `AttendanceMarkDto`
- `JobFairCreateDto`, `JobFairUpdateDto`

---

## 4) API Index by Controller

## 4.1 Auth Controller (`/api/Auth`)

### Login
- `POST /api/Auth/admin/login`
- `POST /api/Auth/company/login`
- `POST /api/Auth/student/login`
- Body: `LoginDto`
- Returns JWT + role/user context.

### Registration & Company onboarding
- `POST /api/Auth/student/register`
  - Body: `StudentRegistrationDto`
- `POST /api/Auth/company-signup`
  - Body: `CompanySignupDto` (`multipart/form-data`)
- `POST /api/Auth/company-verify-otp`
- `POST /api/Auth/company-resend-otp`

### Password recovery / reset
- `POST /api/Auth/forgot-password`
- `POST /api/Auth/verify-reset-token`
- `POST /api/Auth/reset-password`
- `POST /api/Auth/forgot-password/send-otp`
- `POST /api/Auth/forgot-password/verify-otp`

### Password change (logged-in)
- `POST /api/Auth/change-password`
  - Requires valid JWT.

---

## 4.2 Student Controller (`/api/Student`) — mostly Student role

## Profile & identity
- `GET /api/Student/profile`
- `POST /api/Student/name`
- `PUT /api/Student/name`
- `GET /api/Student/name`
- `PUT /api/Student/phone`
- `PUT /api/Student/cgpa`

## Files
- `POST /api/Student/profile-pic` (upload)
- `PUT /api/Student/profile-pic` (replace/update)
- `POST /api/Student/cv` (upload/replace CV)

## Education
- `GET /api/Student/Education`
- `POST /api/Student/Education`
- `PUT /api/Student/education/{educationId}`
- `DELETE /api/Student/education/{educationId}`

## Experience
- `GET /api/Student/experiences`
- `POST /api/Student/experiences`
- `DELETE /api/Student/experiences/{experienceId}`

## Certifications
- `GET /api/Student/certifications`
- `POST /api/Student/certifications`
- `PUT /api/Student/certifications/{certificationId}`
- `DELETE /api/Student/certifications/{certificationId}`

## Achievements
- `GET /api/Student/achievements`
- `POST /api/Student/achievements`
- `PUT /api/Student/achievements/{achievementId}`
- `DELETE /api/Student/achievements/{achievementId}`

## Skills
- `POST /api/Student/skills/add`
- `POST /api/Student/skills/remove`
- `PUT /api/Student/skills`

## Contact links
- `GET /api/Student/contactLinks`
- `POST /api/Student/ContactLink`
- `PUT /api/Student/{linkId}`
- `DELETE /api/Student/{linkId}`

## Project management
- `POST /api/Student/projects` (create project)
- `PUT /api/Student/projects/{projectId}` (update project)
- `POST /api/Student/projects/{projectId}/invite`
- `GET /api/Student/projects/invitations`
- `POST /api/Student/projects/invitations/{inviteId}/respond?accept=true|false`
- `GET /api/Student/projects/{projectId}/members`
- `DELETE /api/Student/projects/{projectId}/members/{studentId}`

### Project authorization behavior
- Team lead (`IsCreator`) can remove other members.
- Any member can remove self (leave project).
- If creator leaves, ownership transfer logic attempts to promote another accepted member.

## Interview requests (student side)
- `POST /api/Student/interview-requests/send`
- `GET /api/Student/interview-requests`
- `DELETE /api/Student/interview-requests/{requestId}`
- `POST /api/Student/interview-requests/{requestId}/accept`
- `POST /api/Student/interview-requests/{requestId}/reject`
- `GET /api/Student/interviews/scheduled`

## Student discovery/dashboard
- `GET /api/Student/companies`
- `GET /api/Student/companies/{companyId}`
- `GET /api/Student/jobs`
- `GET /api/Student/jobs/search`
- `GET /api/Student/jobs/by-company/{companyId}`
- `GET /api/Student/jobs/recommended`
- `GET /api/Student/dashboard`
- `GET /api/Student/participation-history`
- `GET /api/Student/notices` (authorized)

## Diagnostics
- `GET /api/Student/debug-claims`

---

## 4.3 Company Controller (`/api/Company`) — mostly Company role

## FYP/Student discovery
- `GET /api/Company/finalyear-projects`
- `GET /api/Company/finalyear-projects/with-students`
- `GET /api/Company/finalyear-projects/{projectId}/with-students`
- `GET /api/Company/finalyear-projects/{projectId}/full-details`
- `GET /api/Company/finalyear-projects/{projectId}/summary`
- `GET /api/Company/finalyear-projects/{projectId}/export`

## Student listings & filtering
- `GET /api/Company/students`
- `GET /api/Company/students/search-by-skill`
- `GET /api/Company/students/search-by-registration`
- `GET /api/Company/students/search-by-department`
- `GET /api/Company/students/by-interview-status`
- `GET /api/Company/students/{studentId}/profile`
- `GET /api/Company/students/{studentId}/details`
- `GET /api/Company/students/{studentId}/availability`

## Interview request lifecycle (company side)
- `POST /api/Company/interview-requests/send`
- `GET /api/Company/interview-requests/by-company`
- `GET /api/Company/interview-requests/pending`
- `GET /api/Company/interview-requests/all`
- `POST /api/Company/interview-requests/{requestId}/accept`
- `POST /api/Company/interview-requests/{requestId}/reject`
- `GET /api/Company/interview-requests/statistics`

## Interview scheduling/execution
- `POST /api/Company/interviews/schedule`
- `POST /api/Company/students/{studentId}/schedule`
- `POST /api/Company/interviews/{interviewId}/start`
- `POST /api/Company/interviews/{interviewId}/complete`
- `POST /api/Company/walkin/interviewing`
- `POST /api/Company/students/{studentId}/walkin/start`

## Company analytics & participation
- `GET /api/Company/analytics`
- `GET /api/Company/analytics/history`
- `GET /api/Company/participation-prompt`
- `POST /api/Company/participate-active-jobfair`

## Job management
- `GET /api/Company/jobs`
- `POST /api/Company/jobs`
- `PUT /api/Company/jobs/{jobId}`
- `DELETE /api/Company/jobs/{jobId}`
- `POST /api/Company/jobs/{jobId}/copy-to-current-jobfair`

## Company profile & links
- `GET /api/Company/profile`
- `PUT /api/Company/profile`
- `POST /api/Company/contact-links`
- `PUT /api/Company/contact-links/{linkId}`
- `DELETE /api/Company/contact-links/{linkId}`

## Company requests / confirmations / notices
- `POST /api/Company/requests`
- `GET /api/Company/requests`
- `PUT /api/Company/requests/{id}/cancel`
- `POST /api/Company/confirm-attendance`
- `GET /api/Company/confirmation-status`
- `GET /api/Company/notices`
- `POST /api/Company/register-fcm-token`

---

## 4.4 Admin Controller (`/api/Admin`) — Admin role

## Dashboard, analytics & logs
- `GET /api/Admin/dashboard/overview`
- `GET /api/Admin/interviews/stats`
- `GET /api/Admin/interviews-summary`
- `GET /api/Admin/surveys`
- `GET /api/Admin/audit-logs`
- `GET /api/Admin/jobfairs/{jobFairId}/analytics`

## Students management
- `GET /api/Admin/students`
- `GET /api/Admin/students/all`
- `GET /api/Admin/students/advanced-filter`
- `GET /api/Admin/students/{studentId}/details`
- `PUT /api/Admin/students/{studentId}/edit-credentials`
- `PUT /api/Admin/students/{studentId}/profile`
- `POST /api/Admin/students/{studentId}/send-email`
- `POST /api/Admin/students/{studentId}/notify`
- `POST /api/Admin/students/notify-all`
- `POST /api/Admin/students/{studentId}/register-for-fair`

## Companies management
- `GET /api/Admin/companies`
- `GET /api/Admin/companies/filter`
- `GET /api/Admin/companies/{companyId}/details`
- `PUT /api/Admin/companies/{companyId}/profile`
- `POST /api/Admin/companies/onspot`
- `POST /api/Admin/companies/{companyId}/notify`
- `POST /api/Admin/companies/notify-all`
- `POST /api/Admin/companies/{companyId}/register-for-fair`

## Rooms & allocations
- `POST /api/Admin/rooms`
- `POST /api/Admin/rooms/bulk-upload`
- `GET /api/Admin/rooms`
- `GET /api/Admin/rooms/download`
- `GET /api/Admin/rooms/filter`
- `PUT /api/Admin/rooms/{roomId}/status`
- `PUT /api/Admin/rooms/{roomId}/capacity`
- `PUT /api/Admin/rooms/assign-company`
- `PUT /api/Admin/rooms/{roomId}/remove-company`
- `PUT /api/Admin/rooms/tentatively-assign`
- `PUT /api/Admin/rooms/{roomId}/confirm-allotment`
- `DELETE /api/Admin/rooms/{roomId}`

## Job fair lifecycle
- `GET /api/Admin/jobfairs`
- `POST /api/Admin/jobfairs`
- `POST /api/Admin/jobfairs/{jobFairId}/activate`
- `PUT /api/Admin/jobfairs/{jobFairId}`
- `DELETE /api/Admin/jobfairs/{jobFairId}`
- `GET /api/Admin/jobfairs/{jobFairId}/companies`

## Notices / Firebase diagnostics
- `GET /api/Admin/notices` (method-level `[Authorize]`)
- `GET /api/Admin/firebase/config-check`
- `GET /api/Admin/fcm/invalid-tokens-report`
- `POST /api/Admin/fcm/cleanup-invalid-tokens`

## Utility/seed
- `POST /api/Admin/create-onetime`

---

## 4.5 CompanyRequests Controller (`/api/admin/CompanyRequests`) — Admin role

- `GET /api/admin/CompanyRequests`
  - List all company requests for admin queue.
- `PUT /api/admin/CompanyRequests/{id}/status`
  - Approve/reject/update status of a specific request.

---

## 4.6 Attendance Controller (`/api/Attendance`)

## Public/scan endpoints
- `GET /api/Attendance/scan`

## Company action
- `POST /api/Attendance/mark` (Company)
  - Body: `AttendanceMarkDto`

## Admin attendance session controls
- `POST /api/Attendance/generate-daily-qr` (Admin)
- `POST /api/Attendance/generate-token` (Admin)
- `POST /api/Attendance/start-session` (Admin)
- `POST /api/Attendance/end-session` (Admin)
- `GET /api/Attendance/stats/{jobFairId}` (Admin)
- `PUT /api/Attendance/mark-absent` (Admin)
- `PUT /api/Attendance/mark-present` (Admin)

---

## 4.7 Survey Controller (`/api/Survey`)

- `GET /api/Survey/template/{type}`
- `GET /api/Survey/my-status` (Company)
- `POST /api/Survey/submit` (Company)
- `POST /api/Survey/pending`
- `GET /api/Survey/all-companies`
- `GET /api/Survey/no-surveys`
- `POST /api/Survey/submit-both` (Company)
- `GET /api/Survey/company/{companyId}`

---

## 5) Integration Notes for Frontend Developers

### Token storage and forwarding
- Save JWT from login response.
- Pass bearer token for all protected routes.
- For SignalR hub calls, pass access token in connection config.

### File upload endpoints
- Use `multipart/form-data` for:
  - Student profile picture/CV uploads
  - Company signup/profile logo uploads

### Date/time handling
- Scheduling endpoints rely on server-parseable DateTime values.
- Prefer ISO 8601 UTC strings from clients.

### Pagination/filtering
- Several admin/student/company list endpoints support query params for filtering/search/sort.
- Confirm exact query keys in Swagger for each route.

---

## 6) Error Handling Guidelines

Backend typically returns:
- `200`: operation successful
- `400`: validation or business rule failure
- `401`: token missing/invalid
- `403`: role/ownership violation
- `404`: entity not found
- `500`: unexpected server error

Recommendation for clients:
- Parse JSON error body if present (`message` / `Message` patterns are common).
- Show user-friendly fallback text when body is non-JSON.

---

## 7) Suggested Developer Workflow

1. Start backend: `dotnet run` in `Backend`.
2. Open Swagger: `https://localhost:7050/swagger`.
3. Authenticate using login endpoint.
4. Paste JWT in Swagger Authorize modal.
5. Test role-specific endpoints.

---

## 8) Maintenance Rules for This Document

When adding/modifying endpoints:
1. Update the relevant section in this file.
2. Keep route path, method, role, and DTO names in sync with controller code.
3. Add notes for any non-obvious business rule (ownership, status transitions, etc.).

If in doubt, controller source is the source of truth.
