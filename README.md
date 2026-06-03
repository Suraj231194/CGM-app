# Optimus CGM Flutter

Optimus CGM is a Flutter application for continuous glucose monitoring workflows. It provides customer, doctor, and admin workspaces with glucose charts, daily readings, meal impact logging, AI-style coaching summaries, sensor setup, alerts, privacy controls, reports, support flows, and reorder/order history.

## Current Product Surface

- Role-based login for customer, doctor, and admin preview workspaces.
- Customer onboarding with consent, safety terms, and sensor setup path.
- Dashboard with current glucose, chart preview, alerts, meal focus, logbook preview, coaching, and sensor status.
- Full chart and daily readings screens, including previous-date logbook navigation.
- Meal logging with meal score and recent meal history.
- Privacy, alert thresholds, report export, support, account, and dark-mode controls.
- Sensor activation flow with browser preview and native SDK path.
- Doctor patient review and admin operations dashboards.

## Run Locally

```powershell
flutter pub get
flutter run -d chrome
```

For the existing static web preview:

```powershell
flutter build web --no-pub
```

Then refresh the local preview URL, for example:

```text
http://127.0.0.1:8088/#/dashboard
```

## Verification

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --update-goldens test\golden_screens_test.dart
flutter build web --no-pub
```

Golden snapshots live in `test/goldens/`. Temporary comparison artifacts should not be committed from `test/failures/`.

## Environment

Runtime environment is selected with compile-time values:

```powershell
flutter build web --dart-define=APP_ENV=production --dart-define=CGM_APP_ID=... --dart-define=CGM_APP_SECRET=...
```

Supported `APP_ENV` values:

- `development`: local seed data and preview-safe Firebase fallbacks.
- `staging`: remote repository providers using the staging API base URL.
- `production`: remote repository providers using the production API base URL.

## Firebase And Notifications

Firebase Analytics, Crashlytics, and Messaging are initialized when Firebase is configured. Without Firebase app options or native config files, the app runs safely in preview mode.

Production setup checklist:

- Add Android `google-services.json`.
- Add iOS `GoogleService-Info.plist`.
- Add web Firebase options if building web with Firebase enabled.
- Run `flutterfire configure` for project-specific options.
- Confirm notification topics and backend push-token registration endpoints.

## Backend

Repository providers support local seed data in development and remote API repositories for staging/production. API base URLs are defined in `lib/core/env/app_environment.dart`.

Expected backend surfaces include:

- `/auth/sign-in`, `/auth/sign-out`, `/auth/session`, `/auth/refresh`
- `/patients`
- `/patients/{id}/readings`
- `/patients/{id}/meals`
- `/patients/{id}/sensors`
- `/patients/{id}/interpretations`
- `/patients/{id}/orders`
- `/patients/{id}/alerts`
- `/patients/{id}/alert-settings`
- `/patients/{id}/reports`

## Native CGM SDK

The browser preview can show the activation flow but cannot connect to a physical sensor. Android and iOS builds use the native CGM SDK bridge through `CgmSdkService`.

## Release Notes

Before release:

- Run analyzer, tests, goldens, and production build.
- Confirm Firebase config and push notification delivery.
- Confirm backend API contracts and authentication token handling.
- Validate accessibility at mobile and desktop sizes.
- Remove transient build/test failure artifacts.
