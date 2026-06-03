# Firebase Setup Guide — Optimus CGM

## Current Status

Firebase dependencies are included in the app but **config files are not yet added**.  
The app runs safely without them — all Firebase calls are guarded with `Firebase.apps.isNotEmpty` checks.

## Steps to Enable Firebase

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named **Optimus CGM** (or use existing)
3. Enable the following services:
   - **Analytics** (auto-enabled)
   - **Crashlytics** (Build ? Crashlytics ? Enable)
   - **Cloud Messaging** (Build ? Cloud Messaging)

### 2. Add Android App

1. In Firebase Console ? Project Settings ? Add App ? Android
2. Package name: `com.biogenix.optimus.optimus_cgm_flutter`
3. Download `google-services.json`
4. Place it at: `android/app/google-services.json`
5. Add the Google Services plugin to `android/build.gradle.kts`:

```kotlin
// android/build.gradle.kts (project-level)
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

6. Apply plugin in `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

### 3. Add iOS App

1. In Firebase Console ? Project Settings ? Add App ? iOS
2. Bundle ID: `com.biogenix.optimus.optimusCgmFlutter` (check `ios/Runner.xcodeproj`)
3. Download `GoogleService-Info.plist`
4. Place it at: `ios/Runner/GoogleService-Info.plist`
5. In Xcode: drag the file into the Runner group (ensure "Copy items if needed" is checked)

### 4. Verify

```bash
flutter clean
flutter pub get
flutter run
```

Check console logs for:
```
[CrashReporter] initialize firebase_ready=true
[Analytics] initialize {firebase_ready: true}
```

## Alternative: FlutterFire CLI (Recommended)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=your-project-id
```

This auto-generates `firebase_options.dart` and places config files correctly.

Then update `main.dart`:
```dart
import 'firebase_options.dart';

await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

## What Works Without Firebase

| Feature | Without Firebase |
|---|---|
| BLE sensor connection | ? Full functionality |
| Glucose data & charts | ? Full functionality |
| Dark mode, navigation | ? Full functionality |
| Push notifications | ? No remote push (local still works) |
| Crash reporting | ? Falls back to debug console logging |
| Analytics | ? Falls back to debug console logging |
