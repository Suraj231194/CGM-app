# CGM SDK Integration Status

Last updated: June 10, 2026

## Summary

The client-provided CGM SDK files and demo projects were reviewed against this Flutter app. The Android and iOS SDK binaries are present in this project, the native bridges are implemented, and the app flow calls the SDK for authorization, permissions, sensor connection, heartbeat/reconnect, callbacks, and history data.

The activation flow now includes QR scanning and GS1/UDI parsing. For the reviewed Eaglenos D115W label format, the app derives the SDK sensor SN from the QR/UDI payload before calling the native SDK connect method.

Browser/web preview can show the UI only. Real sensor connection requires a real Android or iOS app build on a physical phone.

## Client SDK Files Reviewed

| Source | Purpose | Status |
| --- | --- | --- |
| `New folder/sdk/sdk` | Android SDK demo and `bleHealth-release.aar` | Reviewed |
| `New folder/sdk/sdk/SDK_Documentation.md` | Android SDK integration guide | Reviewed |
| `New folder/StayOnFrameworkDemo(1)` | iOS SDK demo and frameworks | Reviewed |
| `StayOnFramework.xcframework` | iOS CGM framework | Reviewed and integrated |
| `SGFilter.xcframework` | iOS support framework | Reviewed and integrated |

## SDK Integration Done

| Area | Android Status | iOS Status | Project Evidence |
| --- | --- | --- | --- |
| SDK binary added | Done | Done | `android/app/libs/bleHealth-release.aar`, `ios/Runner/Frameworks/StayOnFramework.xcframework`, `ios/Runner/Frameworks/SGFilter.xcframework` |
| SDK dependency linked | Done | Done | `android/app/build.gradle.kts`, `ios/Runner.xcodeproj/project.pbxproj` |
| SDK initialization | Done | Done | `OptimusApplication.kt`, `AppDelegate.swift` |
| Native Flutter bridge | Done | Done | `MainActivity.kt`, `CgmSdkIosBridge.swift` |
| SDK authorization | Done | Done | App passes `appId` and `appSecret` to native SDK auth methods |
| Bluetooth permissions | Done | Done | Android manifest/runtime permission bridge, iOS Bluetooth usage keys |
| Background Bluetooth support | Done | Done | Android heartbeat receivers, iOS `UIBackgroundModes` |
| Sensor connect by SN | Done | Done | Android `connectTargetAndStartScan`, iOS `SOFCGMManager.shared.connect` |
| Disconnect | Done | Done | Android and iOS native bridges expose disconnect |
| SDK callbacks/events | Done | Done | Native event channels send auth, connection, device info, glucose data, progress, and error events |
| Glucose readings mapping | Done | Done | Flutter event bridge applies SDK readings into app state |
| History data fetch | Done | Done | Android history APIs and iOS `getHistoryData` bridge are implemented |
| Android heartbeat/reconnect | Done | Not required in same form | Android heartbeat timer and reconnect callback are implemented |
| Release minify protection | Done | Not applicable | `android/app/proguard-rules.pro` keeps CGM SDK classes |
| Flutter SDK service layer | Done | Done | `lib/services/cgm_sdk_service.dart` |
| UI activation flow | Done | Done | `lib/screens/sensor/sensor_flow_screens.dart` |
| QR scanner activation | Done | Done | `mobile_scanner`, `lib/utils/sensor_serial_parser.dart`, camera permission entries |

## Credential Status

| Credential Item | Where Found | Notes |
| --- | --- | --- |
| Android demo `appId` | `New folder/sdk/sdk/app/build.gradle.kts` | Provided by client demo |
| Android demo `appSecret` | `New folder/sdk/sdk/app/build.gradle.kts` | Present in client demo; keep masked in docs/code comments |
| iOS active `appid` | `StayOnFrameworkDemo(1)/StayOnFrameworkDemo/StayOnFrameworkDemo/ContentView.swift` | Provided by client demo |
| iOS active `appsecrect` | `StayOnFrameworkDemo(1)/StayOnFrameworkDemo/StayOnFrameworkDemo/ContentView.swift` | Present in client demo; keep masked in docs/code comments |
| iOS commented old credential pair | Same `ContentView.swift` file | Present but commented; use only if client confirms |
| Build-time credentials | `--dart-define=CGM_APP_ID`, `--dart-define=CGM_APP_SECRET` | Supported by `EnvConfig`; values are not hardcoded into source |

Do not commit production secrets into public code or documentation. If these demo credentials are used for testing, confirm with the SDK provider/client that they are active and approved for this app.

## Backend / Client Items Still Pending

| Pending Item | Owner | Why It Is Needed | Current App Position |
| --- | --- | --- | --- |
| Confirm production `appId` and `appSecret` | Client / SDK provider / backend | SDK authorization requires valid credentials before connection | App can accept credentials and call SDK auth |
| Decide credential delivery flow | Backend / product | Either backend provides credentials automatically, or user/admin enters them manually | Current UI has provider `appId` and `appSecret` fields |
| Confirm Android and iOS credential pairs | Client / SDK provider | Android and iOS demo credentials may be different | App supports both platforms, but provider must confirm correct pair |
| Provide/confirm sensor serial number source | Backend / device operations | SDK connects to sensor by SN; credentials alone are not enough | App connect flow requires sensor SN |
| User-to-sensor assignment | Backend | App needs to know which patient owns which sensor | App can store/use active sensor SN, but backend mapping must be final |
| Reading upload/sync contract | Backend | Live glucose readings may need to be saved server-side | App receives readings locally; backend API contract should confirm final sync behavior |
| Error/audit logging contract | Backend | Production support needs auth/connect/sync error visibility | App captures SDK events; backend endpoint policy should be confirmed |
| Release signing details | Client / deployment owner | Installable production builds need Android signing and iOS Apple signing | Not part of SDK code; required before store/TestFlight release |

## Real Device Connection Requirements

| Requirement | Required For Connection? | Status |
| --- | --- | --- |
| Valid SDK `appId` and `appSecret` | Yes | Provided in demo, but client must confirm active/production use |
| Correct sensor SN | Yes | Must come from the physical CGM sensor, packaging, QR code, or backend assignment |
| Physical Android/iOS phone | Yes | Browser preview cannot connect to CGM hardware |
| Bluetooth enabled | Yes | User/device setting |
| Bluetooth/location permissions granted | Yes | App requests required permissions |
| Sensor nearby and ready | Yes | Physical device requirement |
| SDK provider authorization server reachable | Yes | Network/provider-side requirement |

## Verification Completed

| Check | Result |
| --- | --- |
| Android SDK binary compared with client AAR | Match confirmed |
| iOS framework binaries compared with client frameworks | Match confirmed |
| Flutter analysis | Passed |
| Focused Flutter tests | Passed: SDK service, sensor serial parser, CGM connection state |
| Full Flutter test suite | Existing shader backend issue remains in golden/widget tests (`ink_sparkle.frag` SkSL/Vulkan mismatch) |
| APK build | Passed; release APK generated at `build/app/outputs/flutter-apk/app-release.apk` |
| Live CGM device test | Pending physical Android phone test with Bluetooth enabled and sensor nearby |
| iOS compile/install test | Pending Mac/Xcode/Apple signing environment |

## Final Conclusion

Based on the current client SDK documentation and demo projects, the SDK integration in this app is complete from the application side. The current Android APK includes SDK authorization support, QR-based sensor SN capture, native BLE connection, heartbeat/reconnect, callbacks, and history sync.

Only real-device validation remains: install the APK on a physical Android phone, authorize the SDK, scan or enter the sensor SN, and keep the sensor nearby with Bluetooth enabled.
