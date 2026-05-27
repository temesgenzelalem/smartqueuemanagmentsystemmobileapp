# Smart Queue Management System — Mobile App

Staff-only Flutter application for **Admin** and **Accountant** roles. Connects to the existing Laravel API (`tsehay-backend`) without backend changes. Customer login is blocked in the mobile client.

## Stack

- Flutter (stable)
- Riverpod
- Dio
- Hive (offline cache placeholders)
- Firebase Core / Messaging (placeholder configuration)
- Codemagic CI/CD (Android-first)

## Project structure

```
lib/
├── core/          # constants, routes, theme, env/hive/firebase/offline services
├── models/
├── providers/
├── screens/       # auth, admin, accountant
├── services/      # API, auth, queue, transactions, reports, windows
├── widgets/
└── main.dart
```

## Prerequisites

- Flutter SDK (stable channel)
- Laravel API running (see parent repo `tsehay-backend`)
- Codemagic account (for cloud builds — no local Android build required)

## Configuration

1. Copy environment template:

```bash
cp .env.example .env
```

2. Set your API base URL (must include `/api`):

```
API_BASE_URL=https://your-domain.com/api
```

For local Laravel:

```
API_BASE_URL=http://10.0.2.2:8000/api
```

(`10.0.2.2` is the Android emulator alias for host `127.0.0.1`.)

3. Optional: pass at build/run time:

```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.com/api
```

Bundled defaults live in `assets/config.env` (overwritten in Codemagic).

## Local commands

```bash
cd tsehay-mobileapp   # or repo root if this is the root project
flutter pub get
flutter analyze
flutter test
flutter run
```

## Android build (local or Codemagic)

Debug APK:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=https://your-domain.com/api
```

Release APK (requires signing setup):

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-domain.com/api
```

Output: `build/app/outputs/flutter-apk/`

### Codemagic

1. Connect this GitHub repository in [Codemagic](https://codemagic.io).
2. Enable **codemagic.yaml** as the configuration source.
3. Set environment variable `API_BASE_URL` in Codemagic (or edit `codemagic.yaml`).
4. Trigger workflow **android-staff-app**.

Docs:

- [Flutter projects on Codemagic](https://docs.codemagic.io/flutter-configuration/flutter-projects/)
- [codemagic.yaml reference](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/)

## API compatibility (Laravel)

| Role        | Endpoints used |
|------------|----------------|
| Auth       | `POST /login`, `POST /logout` |
| Admin      | `/admin/*`, `/accountants`, `/windows`, `/transactions/{period}` |
| Accountant | `/queue`, `/queue/select/{id}`, `/queue/complete/{id}` |

Customer routes are **not** exposed in this app; customer role logins are rejected.

## Firebase (placeholders)

Replace values in `.env` / Codemagic vars when enabling push notifications. Until then, `FirebaseService` initializes with placeholder options and continues if Firebase is unavailable.

## Push to GitHub

```bash
git init
git add .
git commit -m "Initial Smart Queue staff mobile app"
git branch -M main
git remote add origin https://github.com/temesgenzelalem/smartqueuemanagmentsystemmobileapp.git
git push -u origin main
```

## License

Proprietary — Tsehay Bank Smart Queue project.
