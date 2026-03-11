# Student Portal

Flutter-based student-facing application for the COMSATS Open House & Job Fair platform.

## Tech Stack

- Flutter (Dart SDK `^3.8.1`)
- Provider (state management)
- Firebase Messaging + local notifications
- HTTP + shared_preferences

## Supported Platforms

- Web (actively used)
- Android / iOS
- Desktop folders are present (Windows/macOS/Linux)

## Prerequisites

- Flutter SDK compatible with Dart `3.8.x`
- Chrome (for web debug)
- Backend API running and reachable
- Firebase project configured for notifications

## Common Commands

```bash
flutter pub get
flutter run -d chrome
flutter test
flutter analyze
flutter build web --release
```

## Backend URL Configuration

Backend endpoint configuration is centralized in:

- `lib/config/backend_config.dart`

Default base URL:
- `http://192.168.137.1:5158`

To override at build/run time, pass a Dart define:

```bash
flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://localhost:5158
```

For release web build:

```bash
flutter build web --release --dart-define=BACKEND_BASE_URL=http://localhost:5158
```

## Project Structure (Important Areas)

- `lib/screens/` — app screens (profile, jobs, companies, requests, settings)
- `lib/provider/` — app state and backend interaction
- `lib/model/` — data models
- `lib/widgets/` — shared UI components
- `lib/services/` — feature services (for example CV generation)
- `lib/config/backend_config.dart` — backend base URL helper

## Notifications

For web push notifications and service-worker setup, see:

- `WEB_NOTIFICATIONS_SETUP.md`
- `NOTIFICATIONS_IMPLEMENTATION.md`

## Web Build Notes

Additional optimization/help docs:

- `QUICK_START_SMALL_BUILD.md`
- `BUILD_SMALL_HTML_GUIDE.md`
- `build_small_web.ps1`

## Troubleshooting

### API requests fail
- Verify backend is running and URL is correct.
- Use `--dart-define=BACKEND_BASE_URL=...` to match your local backend host.

### Images/files not loading
- Ensure backend static files are exposed and URLs are absolute/valid.

### Web notifications not appearing
- Check browser notification permissions.
- Verify Firebase web config and service worker setup.

### Login/session issues
- Clear browser storage and retry.
- Confirm JWT-related endpoints are reachable from current base URL.
