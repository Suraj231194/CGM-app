/// This file documents the widget structure of large screens.
/// When these files grow further, extract widgets into separate files
/// following this pattern:
///
/// customer_dashboard_screen.dart (1396 lines) contains:
/// - CustomerDashboardScreen (main widget)
/// - _HomeHero (hero card with reading + copy panels)
/// - _HeroReadingPanel
/// - _HeroCopyPanel
/// - _AlertBanner
/// - _GlucoseStoryCard
/// - _QuickActionDeck
/// - _NutritionFocusCard
/// - _LogbookPreview
/// - _GuidanceCard
/// - _SensorStatusCard
///
/// Recommended split:
///   screens/customer/dashboard/
///     ??? customer_dashboard_screen.dart (main)
///     ??? widgets/home_hero.dart
///     ??? widgets/alert_banner.dart
///     ??? widgets/glucose_story_card.dart
///     ??? widgets/quick_action_deck.dart
///     ??? widgets/nutrition_focus_card.dart
///     ??? widgets/logbook_preview.dart
///     ??? widgets/guidance_card.dart
///     ??? widgets/sensor_status_card.dart
///
/// sensor_flow_screens.dart (795 lines) contains:
/// - SensorActivationIntroScreen
/// - AttachSensorInstructionsScreen
/// - ScanSensorScreen
/// - WarmupCountdownScreen
/// - SensorStatusScreen
/// - Various helper widgets
///
/// Recommended split:
///   screens/sensor/
///     ??? sensor_activation_intro_screen.dart
///     ??? attach_sensor_screen.dart
///     ??? scan_sensor_screen.dart
///     ??? warmup_countdown_screen.dart
///     ??? sensor_status_screen.dart
///     ??? widgets/sensor_shared_widgets.dart
///
/// NOTE: The current monolithic files still work correctly.
/// This split should be done when adding new features to these screens.
library;
