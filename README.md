# Tsehay Bank Smart Queue — Mobile App

A unified Flutter mobile app for **all roles**: Admin, Accountant/Window Staff, and **Customers**.

## Features

### Customer
- Sign up with email/password (real email verification required before login)
- Sign in with Google account (no verification needed)
- Submit deposit / withdrawal / transfer requests with photo + signature
- View live queue status (auto-refreshes every 5 seconds)
- Notified when called to the window
- View completed transaction receipts

### Admin / Manager
- Live queue dashboard across all windows
- Create / delete accountant staff
- View and filter transaction reports (daily, weekly, monthly, yearly)
- Configure withdrawal limits

### Accountant / Window Staff
- View own queue
- Select and process customers
- Complete transactions
- Upload receipt images

## Stack

- Flutter (stable)
- Laravel API (`tsehay-backend`) — Laravel Sanctum authentication
- Google Sign-In via `google_sign_in` package
- Signature pad via `signature` package

## API configuration

Set `API_BASE_URL` at build time (must include `/api`):

```bash
flutter run \
  --dart-define=API_BASE_URL=https://smartqueuemanagmentsystem-backend.onrender.com/api \
  --dart-define=GOOGLE_CLIENT_ID=<your-android-client-id>
```

## Google Sign-In setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create an **Android OAuth Client ID** (application type: Android)
3. Use your app's package name and SHA-1 fingerprint
4. Set `GOOGLE_CLIENT_ID` in Codemagic environment variables (or `codemagic.yaml`)
5. Also set `GOOGLE_CLIENT_ID` in your Laravel backend's `.env` so token verification works

## Codemagic build

1. Connect this GitHub repository in Codemagic
2. Enable **codemagic.yaml** as the configuration source
3. Set environment variables:
   - `API_BASE_URL` = `https://smartqueuemanagmentsystem-backend.onrender.com/api`
   - `GOOGLE_CLIENT_ID` = your Android OAuth client ID
4. Trigger workflow **android-release**

## Backend — new endpoints added

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/api/auth/google` | Google sign-in — accepts `id_token`, returns Sanctum token |

All existing customer endpoints remain unchanged:

| Method | Path | Role |
|--------|------|------|
| `POST` | `/api/register` | Public |
| `POST` | `/api/login` | Public |
| `POST` | `/api/email/resend` | Public |
| `GET` | `/api/my-transactions` | Customer |
| `POST` | `/api/transactions` | Customer |
| `GET` | `/api/my-receipts` | Customer |
| `GET` | `/api/available-windows` | Any auth |

## Default admin credentials (seeded)

| Field | Value |
|-------|-------|
| Email | `admin@tsehay.com` |
| Password | `12345678` |

## License

Proprietary — Tsehay Bank Smart Queue project.
