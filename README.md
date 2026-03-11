# COMSATS Open House & Job Fair Portal

A full-stack platform for managing COMSATS Wah Open House and Job Fair operations, built with an ASP.NET Core backend and role-based portals for students, companies, and admins.

This repository contains:
- `Backend` (ASP.NET Core Web API + SignalR + PostgreSQL)
- `admin-portal` (React + Vite)
- `company-portal` (React + Vite)
- `student-portal` (Flutter, primarily web/mobile)

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Tech Stack](#tech-stack)
4. [Repository Structure](#repository-structure)
5. [Prerequisites](#prerequisites)
6. [Quick Start (End-to-End)](#quick-start-end-to-end)
7. [Backend Setup (.NET API)](#backend-setup-net-api)
8. [Admin Portal Setup](#admin-portal-setup)
9. [Company Portal Setup](#company-portal-setup)
10. [Student Portal Setup (Flutter)](#student-portal-setup-flutter)
11. [Environment & Configuration](#environment--configuration)
12. [Database & Migrations](#database--migrations)
13. [Notifications (Firebase + SignalR)](#notifications-firebase--signalr)
14. [Troubleshooting](#troubleshooting)
15. [Backend API Documentation](#backend-api-documentation)
16. [Recommended Improvements](#recommended-improvements)

---

## Project Overview

The platform supports complete job fair operations:

- **Students** can sign up, manage profiles, view jobs/companies, and interact with fair-related workflows.
- **Companies** can sign in, register for participation, search student profiles, and manage recruitment interactions.
- **Admins** can manage job fairs, students, companies, attendance sessions/QR workflows, and communication.
- **Backend services** expose role-based APIs, authentication, file uploads, and real-time updates.

---

## Architecture

```text
┌──────────────────────────────────────────────────────────────────────┐
│                     Frontend / Client Applications                   │
│                                                                      │
│  Admin Portal (React/Vite)   Company Portal (React/Vite)             │
│  Student Portal (Flutter Web / Mobile)                               │
└───────────────────────────────┬──────────────────────────────────────┘
								│ HTTP/HTTPS + JWT
								▼
┌──────────────────────────────────────────────────────────────────────┐
│                     Backend (ASP.NET Core .NET 8)                    │
│  Controllers | Services | EF Core | SignalR Hubs | Swagger           │
└───────────────────────────────┬──────────────────────────────────────┘
								│
			    ┌───────────────┴───────────────┐
				▼                               ▼
			PostgreSQL (primary DB)        Firebase Cloud Messaging
```

---

## Tech Stack

### Backend
- .NET 8 (`Microsoft.NET.Sdk.Web`)
- ASP.NET Core Web API
- Entity Framework Core + Npgsql (PostgreSQL)
- JWT Authentication
- SignalR (real-time updates)
- Swagger/OpenAPI
- Firebase Admin SDK

### Admin Portal
- React 19
- Vite 7
- Tailwind CSS
- Axios
- SignalR JS client

### Company Portal
- React 18
- Vite 5
- Tailwind CSS
- Firebase JS SDK

### Student Portal
- Flutter (Dart SDK `^3.8.1`)
- Provider state management
- Firebase Messaging

---

## Repository Structure

```text
jobfair-portal/
├─ README.md
├─ Backend/
│  ├─ JobFairPortal.sln
│  ├─ JobFairPortal.csproj
│  ├─ Program.cs
│  ├─ Controllers/
│  ├─ Data/
│  ├─ DTOs/
│  ├─ Models/
│  ├─ Services/
│  ├─ Migrations/
│  ├─ config/
│  └─ uploads/
├─ admin-portal/
├─ company-portal/
└─ student-portal/
```

---

## Prerequisites

Install the following before running locally:

- **.NET SDK 8.x**
- **Node.js 18+** and npm
- **Flutter SDK** (compatible with Dart `^3.8.1`)
- **PostgreSQL 14+** (or compatible)
- **Git**

Optional but recommended:
- Android Studio / VS Code Flutter tooling (for mobile builds)
- Firebase project configuration (for push notifications)

---

## Quick Start (End-to-End)

From the repository root, run each component in a separate terminal:

1. Start backend API
2. Start admin portal
3. Start company portal
4. Start student portal

### 1) Backend

```bash
cd Backend
dotnet restore
dotnet run
```

Default API endpoints in development (from `Program.cs`):
- `http://localhost:5158`
- `https://localhost:7050`

### 2) Admin Portal

```bash
cd admin-portal
npm install
npm run dev
```

Default dev port:
- `http://localhost:5174`

### 3) Company Portal

```bash
cd company-portal
npm install
npm run dev
```

Default Vite port:
- Usually `5173` unless occupied

### 4) Student Portal (Flutter)

```bash
cd student-portal
flutter pub get
flutter run -d chrome
```

For optimized web build:

```bash
flutter build web --release
```

---

## Backend Setup (.NET API)

### Key files
- `Backend/Program.cs`
- `Backend/appsettings.json`
- `Backend/Data/JobFairRecruitmentDbContext.cs`

### API capabilities
- JWT-based authentication and authorization
- Role-driven endpoints (Admin, Company, Student)
- SignalR hub: `/hubs/companyRequests`
- Static file serving for uploaded content via `/uploads`
- Swagger in Development environment

### Local run

```bash
cd Backend
dotnet run
```

Swagger URL (development):
- `https://localhost:7050/swagger`

### API docs for developers

- Detailed backend API reference: `Backend/API_DOCUMENTATION.md`
- Recommended onboarding flow:
	1. Read `Backend/API_DOCUMENTATION.md`
	2. Start backend and open Swagger (`/swagger`)
	3. Authenticate with role-specific login endpoints
	4. Test protected routes with bearer token

---

## Backend API Documentation

For complete controller-wise API docs (routes, roles, common DTOs, and integration notes), see:

- `Backend/API_DOCUMENTATION.md`

This file is intended for new developers joining the project and should be updated whenever endpoints are added/changed.

---

## Admin Portal Setup

### Scripts

```bash
cd admin-portal
npm install
npm run dev
npm run build
npm run preview
```

### API configuration

Admin portal API helper supports:
- `VITE_BACKEND_URL` (optional)
	- If unset, API requests use relative `/api` and rely on Vite proxy.

SignalR service supports:
- `VITE_API_BASE_URL` (optional)
	- Defaults to `http://localhost:5158`.

---

## Company Portal Setup

### Scripts

```bash
cd company-portal
npm install
npm run dev
npm run build
npm run preview
```

### API configuration

Company portal API helper supports:
- `VITE_SERVER_URL` (optional)
	- If unset, requests use relative `/api` and Vite proxy.

Vite proxy currently targets backend at:
- `http://192.168.137.1:5158` for `/api` and `/uploads`

Adjust this target for your local environment if needed.

---

## Student Portal Setup (Flutter)

### Scripts

```bash
cd student-portal
flutter pub get
flutter run -d chrome
flutter test
```

### Notes
- The student portal currently includes multiple hardcoded backend URLs (e.g. `http://192.168.137.1:5158`).
- To run smoothly in your environment, update those endpoints or centralize them into one config source.
- Web notifications are documented in `student-portal/WEB_NOTIFICATIONS_SETUP.md`.

---

## Environment & Configuration

### Backend (`Backend/appsettings.json`)

Configure:
- `ConnectionStrings:DefaultConnection`
- `Jwt:Key`, `Jwt:Issuer`, `Jwt:Audience`
- `Firebase:ServiceAccountPath`
- `Smtp:*`

### Frontends

You can create `.env` files in `admin-portal` and `company-portal` as needed.

Example (admin portal):

```env
VITE_BACKEND_URL=https://localhost:7050
VITE_API_BASE_URL=http://localhost:5158
```

Example (company portal):

```env
VITE_SERVER_URL=http://localhost:5158
```

---

## Database & Migrations

EF Core migrations exist under `Backend/Migrations`.

Typical flow:

```bash
cd Backend
dotnet ef database update
```

If EF CLI is not installed:

```bash
dotnet tool install --global dotnet-ef
```

---

## Notifications (Firebase + SignalR)

### Firebase (mobile/web push)
- Backend uses Firebase Admin for messaging workflows.
- Student portal handles FCM and browser notification permissions for web.

### SignalR (real-time admin/company updates)
- Hub endpoint: `/hubs/companyRequests`
- Admin portal connects using `@microsoft/signalr` and bearer tokens.

---

## Troubleshooting

### Backend won’t start
- Check PostgreSQL is running and credentials in `appsettings.json` are valid.
- Verify .NET SDK version with `dotnet --version`.

### CORS or API request failures
- Ensure frontend proxy targets match the machine running backend.
- If mixing HTTPS frontend with HTTP backend, use same-origin proxy or HTTPS backend URL.

### SignalR connection issues
- Confirm backend is running and hub route is reachable.
- Verify JWT token exists in local storage after login.

### Flutter web notification issues
- Verify service worker setup and browser notification permissions.
- Confirm Firebase web app config is correct.

---

## Recommended Improvements

For better maintainability and security:

1. **Move secrets out of source-controlled config** into environment variables / secret storage.
2. **Centralize backend URL config** across student portal to avoid repeated hardcoded IPs.
3. **Add `.env.example` files** for admin/company portals.
4. **Expand backend README** with endpoint inventory and auth flow diagrams.
5. **Add CI checks** (build, lint, test) for all subprojects.

---

## License

No license file is currently defined in this repository.
If this project will be shared publicly, add an explicit `LICENSE` file.
