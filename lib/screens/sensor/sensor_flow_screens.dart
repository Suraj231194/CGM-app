import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme.dart';
import '../../core/env/app_environment.dart';
import '../../models/optimus_models.dart';
import '../../services/cgm_sdk_service.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../utils/sensor_serial_parser.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';

bool get _isNativeSdkAvailable =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class SensorActivationIntroScreen extends ConsumerStatefulWidget {
  const SensorActivationIntroScreen({super.key});

  @override
  ConsumerState<SensorActivationIntroScreen> createState() =>
      _SensorActivationIntroScreenState();
}

class _SensorActivationIntroScreenState
    extends ConsumerState<SensorActivationIntroScreen> {
  var _authorizing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isNativeSdkAvailable) {
        _autoAuthorizeIfNeeded();
      }
    });
  }

  Future<void> _autoAuthorizeIfNeeded() async {
    final appState = ref.read(appControllerProvider);
    final service = CgmSdkService.instance;
    final isAuthorized =
        appState.cgmAuthorized || await service.checkAuthorized();
    if (!mounted) return;
    if (isAuthorized) {
      if (!appState.cgmAuthorized) {
        ref
            .read(appControllerProvider.notifier)
            .setCgmAuthState(authorized: true);
      }
      return;
    }
    await _authorizeSdk(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final sensor = ref.watch(selectedSensorProvider);
    final appState = ref.watch(appControllerProvider);
    final nativeAvailable = _isNativeSdkAvailable;

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Sensor',
          title: 'Sensor activation',
          subtitle: 'Prepare and activate your CGM sensor.',
        ),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(
                label: sensor?.status.name.toUpperCase() ?? 'NO SENSOR',
                color: AppColors.primary,
                icon: Icons.sensors_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                sensor?.serialNumber ?? 'Prepare a new Optimus CGM sensor',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Follow the guided steps to attach, scan, and activate your continuous glucose monitor.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),

              // SDK Status Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: appState.cgmAuthorized
                      ? AppColors.primarySoft
                      : AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      appState.cgmAuthorized
                          ? Icons.verified_user_rounded
                          : Icons.gpp_bad_rounded,
                      color: appState.cgmAuthorized
                          ? AppColors.primary
                          : AppColors.danger,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.cgmAuthorized
                                ? 'SDK Authenticated'
                                : 'SDK Needs Authentication',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: appState.cgmAuthorized
                                      ? AppColors.primary
                                      : AppColors.danger,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appState.cgmAuthorized
                                ? 'Connected to Eaglenos service using config file credentials.'
                                : 'Failed to authenticate SDK. Please verify config file credentials.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (!appState.cgmAuthorized && nativeAvailable)
                      IconButton(
                        onPressed: _authorizing
                            ? null
                            : () => _authorizeSdk(context, ref),
                        icon: _authorizing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        color: AppColors.danger,
                      ),
                  ],
                ),
              ),

              if (!nativeAvailable) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Native sensor connection is available in Android and iOS app builds. Browser preview can show the activation steps but will not connect to a physical sensor.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
              if (appState.cgmLastError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  appState.cgmLastError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Start sensor activation',
                    content:
                        'This will begin the sensor activation process. Make sure you have a new sensor pack ready.',
                    confirmLabel: 'Start',
                  );
                  if (!confirmed || !context.mounted) return;
                  ref
                      .read(appControllerProvider.notifier)
                      .startSensorActivation();
                  unawaited(context.push('/sensor/attach'));
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start activation'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _authorizeSdk(BuildContext context, WidgetRef ref) async {
    final env = EnvConfig.current;
    final appId = env.cgmSdkAppId;
    final appSecret = env.cgmSdkAppSecret;
    if (appId.isEmpty || appSecret.isEmpty) {
      ref
          .read(appControllerProvider.notifier)
          .setCgmAuthState(
            authorized: false,
            error: 'SDK appId or appSecret is missing from configuration.',
          );
      return;
    }

    setState(() => _authorizing = true);
    final controller = ref.read(appControllerProvider.notifier);
    try {
      final service = CgmSdkService.instance;
      await service.requestBluetoothPermissions();
      final authorized = await service.auth(appId: appId, appSecret: appSecret);
      controller.setCgmAuthState(
        authorized: authorized,
        error: authorized ? null : 'SDK authorization was not accepted.',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authorized ? 'SDK authorized.' : 'SDK authorization failed.',
            ),
          ),
        );
      }
    } catch (error) {
      controller.setCgmAuthState(authorized: false, error: error.toString());
    } finally {
      if (mounted) setState(() => _authorizing = false);
    }
  }
}

class AttachSensorInstructionsScreen extends ConsumerWidget {
  const AttachSensorInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Step 1',
          title: 'Attach sensor',
          subtitle: 'Follow these steps to attach your sensor correctly.',
        ),
        const _InstructionStep(number: '1', title: 'Clean and dry the site'),
        const _InstructionStep(number: '2', title: 'Apply the sensor firmly'),
        const _InstructionStep(
          number: '3',
          title: 'Keep phone nearby for Bluetooth pairing',
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () {
            ref.read(appControllerProvider.notifier).attachSensor();
            context.push('/sensor/scan');
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Sensor attached'),
        ),
      ],
    );
  }
}

class ScanSensorScreen extends ConsumerStatefulWidget {
  const ScanSensorScreen({super.key});

  @override
  ConsumerState<ScanSensorScreen> createState() => _ScanSensorScreenState();
}

class _ScanSensorScreenState extends ConsumerState<ScanSensorScreen> {
  late final TextEditingController _serialController;
  var _connecting = false;
  var _connectionFailed = false;
  var _elapsedSeconds = 0;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    final sensor = ref.read(selectedSensorProvider);
    final state = ref.read(appControllerProvider);
    _serialController = TextEditingController(
      text: state.cgmSensorSn ?? sensor?.serialNumber ?? '',
    );
  }

  @override
  void dispose() {
    _serialController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final nativeAvailable = _isNativeSdkAvailable;

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Step 2',
          title: 'Scan and connect',
          subtitle: 'Hold your phone near the sensor to pair.',
        ),
        PremiumCard(
          child: Column(
            children: [
              const Icon(
                Icons.bluetooth_searching_rounded,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ready to scan',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                nativeAvailable
                    ? 'Hold your phone near the sensor to scan and establish a Bluetooth connection.'
                    : 'Enter a serial number to preview the activation flow. Physical Bluetooth connection requires Android or iOS.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _serialController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Sensor serial number',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _connecting
                      ? null
                      : () => unawaited(
                          _scanQrAndConnect(context, ref, nativeAvailable),
                        ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan QR code'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (appState.cgmConnectionStatus.isNotEmpty)
                StatusPill(
                  label: appState.cgmConnected
                      ? 'CONNECTED'
                      : appState.cgmConnecting || _connecting
                      ? 'CONNECTING'
                      : appState.cgmConnectionStatus.toUpperCase(),
                  color: appState.cgmConnected
                      ? AppColors.success
                      : appState.cgmLastError == null
                      ? AppColors.primary
                      : AppColors.danger,
                  icon: appState.cgmConnected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_searching_rounded,
                ),
              if (appState.cgmLastError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  appState.cgmLastError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              if (_connecting) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Searching for sensor� ${_elapsedSeconds}s / 30s',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  child: LinearProgressIndicator(
                    value: _elapsedSeconds / 30.0,
                    minHeight: 4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _connecting
                          ? null
                          : () =>
                                _scanAndConnect(context, ref, nativeAvailable),
                      icon: _connecting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.radar_rounded),
                      label: Text(
                        _connectionFailed ? 'Retry' : 'Connect sensor',
                      ),
                    ),
                  ),
                  if (_connecting) ...[
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _cancelConnection,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _cancelConnection() {
    _stopElapsedTimer();
    CgmSdkService.instance.disconnect();
    final controller = ref.read(appControllerProvider.notifier);
    controller.setCgmConnectionState(
      status: 'Connection cancelled',
      connected: false,
      connecting: false,
      sensorSn: _serialController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _connecting = false;
        _connectionFailed = true;
      });
    }
  }

  Future<void> _scanQrAndConnect(
    BuildContext context,
    WidgetRef ref,
    bool nativeAvailable,
  ) async {
    final rawScan = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _SensorQrScannerSheet(),
    );
    if (!context.mounted || rawScan == null) return;

    final serial = parseSensorSerialFromQr(rawScan);
    if (serial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR scanned, but no sensor serial number was found.'),
        ),
      );
      return;
    }

    _serialController.text = serial;
    ref
        .read(appControllerProvider.notifier)
        .addCgmLog('QR scan captured sensor serial.');
    await _scanAndConnect(context, ref, nativeAvailable);
  }

  Future<void> _scanAndConnect(
    BuildContext context,
    WidgetRef ref,
    bool nativeAvailable,
  ) async {
    final serial = parseSensorSerialFromQr(_serialController.text);
    if (serial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter or scan a valid sensor serial number.'),
        ),
      );
      return;
    }
    _serialController.text = serial;

    final controller = ref.read(appControllerProvider.notifier);
    final service = CgmSdkService.instance;

    if (nativeAvailable) {
      final appState = ref.read(appControllerProvider);
      final authorized =
          appState.cgmAuthorized || await service.checkAuthorized();
      if (!authorized) {
        controller.setCgmConnectionState(
          status: 'SDK authorization required',
          connected: false,
          connecting: false,
          sensorSn: serial,
          error: 'Authorize the CGM SDK with appId and appSecret first.',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authorize the SDK before connecting the sensor.'),
            ),
          );
        }
        return;
      }
      if (!appState.cgmAuthorized) {
        controller.setCgmAuthState(authorized: true);
      }
    }

    controller.scanAndConnectSensor(
      serialNumber: serial,
      previewOnly: !nativeAvailable,
    );

    if (!nativeAvailable) {
      if (context.mounted) unawaited(context.push('/sensor/warmup'));
      return;
    }

    setState(() {
      _connecting = true;
      _connectionFailed = false;
    });
    _startElapsedTimer();
    try {
      final permissionStatus = await service.requestBluetoothPermissions();
      if (permissionStatus != 'granted') {
        _stopElapsedTimer();
        final message = permissionStatus == 'permanentlyDenied'
            ? 'Bluetooth permissions are permanently denied. Enable Nearby devices in Android settings and try again.'
            : permissionStatus == 'error'
            ? 'Could not request Bluetooth permission. Open Android app settings, enable Nearby devices, and try again.'
            : 'Bluetooth permissions were not granted. Please allow Nearby devices/Bluetooth permission and try again.';
        controller.setCgmConnectionState(
          status: 'Bluetooth permission required',
          connected: false,
          connecting: false,
          sensorSn: serial,
          error: message,
        );
        if (mounted) {
          setState(() {
            _connecting = false;
            _connectionFailed = true;
          });
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          if (permissionStatus == 'permanentlyDenied' ||
              permissionStatus == 'error') {
            await _showPermissionSettingsDialog(
              context,
              title: 'Bluetooth permission required',
              message:
                  'Open app settings and allow Nearby devices/Bluetooth access for Optimus CGM.',
            );
          }
        }
        return;
      }

      // Check Bluetooth state after permission is granted. Android 12+ requires
      // BLUETOOTH_CONNECT even to read adapter state.
      final btEnabled = await service.isBluetoothEnabled();
      if (!btEnabled) {
        _stopElapsedTimer();
        controller.setCgmConnectionState(
          status: 'Bluetooth disabled',
          connected: false,
          connecting: false,
          sensorSn: serial,
          error:
              'Bluetooth is turned off. Please enable Bluetooth in your device settings.',
        );
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Bluetooth Required'),
              content: const Text(
                'Bluetooth is not enabled. Please turn on Bluetooth in your device settings and try again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        if (mounted) {
          setState(() {
            _connecting = false;
            _connectionFailed = true;
          });
        }
        return;
      }

      final connected = await service.connect(sensorSn: serial);

      _stopElapsedTimer();
      if (connected) {
        unawaited(HapticFeedback.mediumImpact());
        controller.setCgmConnectionState(
          status: 'Sensor connected',
          connected: true,
          connecting: false,
          sensorSn: serial,
        );
        await service.startHeartbeat();
        try {
          final history = await service.getHistoryFromIndexStart(
            sensorSn: serial,
          );
          if (history.isNotEmpty) {
            controller.applyCgmReadings(history);
          }
        } catch (_) {
          controller.addCgmLog(
            'History sync will continue from SDK callbacks.',
          );
        }
        if (context.mounted) unawaited(context.push('/sensor/warmup'));
      } else {
        final latestError = ref.read(appControllerProvider).cgmLastError;
        // Connection returned false � sensor not found or timed out
        controller.setCgmConnectionState(
          status: 'Connection failed',
          connected: false,
          connecting: false,
          sensorSn: serial,
          error:
              latestError ??
              'Could not connect to sensor. Ensure the sensor is nearby, powered on, and Bluetooth is enabled.',
        );
        if (mounted) setState(() => _connectionFailed = true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Connection failed. Check sensor proximity and try again.',
              ),
            ),
          );
        }
      }
    } catch (error) {
      _stopElapsedTimer();
      controller.setCgmConnectionState(
        status: 'Sensor connection failed',
        connected: false,
        connecting: false,
        sensorSn: serial,
        error: error.toString(),
      );
      if (mounted) setState(() => _connectionFailed = true);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection error: $error')));
      }
    } finally {
      _stopElapsedTimer();
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _showPermissionSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(CgmSdkService.instance.openAppPermissionSettings());
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}

class _SensorQrScannerSheet extends StatefulWidget {
  const _SensorQrScannerSheet();

  @override
  State<_SensorQrScannerSheet> createState() => _SensorQrScannerSheetState();
}

class _SensorQrScannerSheetState extends State<_SensorQrScannerSheet> {
  late final MobileScannerController _controller;
  var _handledScan = false;
  var _cameraReady = false;
  var _checkingCamera = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
      autoStart: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_prepareCamera());
    });
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.86,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scan device QR',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _handleDetect,
                        errorBuilder: (context, error) {
                          return ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  error.errorDetails?.message ??
                                      error.errorCode.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (!_cameraReady)
                        ColoredBox(
                          color: Colors.black,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_checkingCamera)
                                    const SizedBox.square(
                                      dimension: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.no_photography_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    _errorText ?? 'Starting camera...',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (!_checkingCamera) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    FilledButton(
                                      onPressed: () => unawaited(
                                        CgmSdkService.instance
                                            .openAppPermissionSettings(),
                                      ),
                                      child: const Text('Open settings'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          height: 232,
                          width: 232,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            border: Border.all(
                              color: AppColors.onDark,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              _errorText ??
                                  'Align the QR code inside the frame.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cameraReady
                          ? () => unawaited(_controller.toggleTorch())
                          : null,
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('Torch'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cameraReady
                          ? () => unawaited(_controller.switchCamera())
                          : null,
                      icon: const Icon(Icons.cameraswitch_rounded),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _prepareCamera() async {
    final permissionStatus = await CgmSdkService.instance
        .requestCameraPermission();
    if (!mounted) return;

    if (permissionStatus != 'granted' && permissionStatus != 'error') {
      setState(() {
        _checkingCamera = false;
        _cameraReady = false;
        _errorText = permissionStatus == 'permanentlyDenied'
            ? 'Camera permission is permanently denied. Enable camera access in Android settings and try again.'
            : 'Camera permission was not granted. Please allow camera access to scan the QR code.';
      });
      return;
    }

    try {
      await _controller.start();
      if (!mounted) return;
      setState(() {
        _checkingCamera = false;
        _cameraReady = true;
        _errorText = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checkingCamera = false;
        _cameraReady = false;
        _errorText =
            'Camera could not start. Close other apps using the camera and try again.';
      });
    }
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handledScan) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }
    if (rawValue == null) return;

    final serial = parseSensorSerialFromQr(rawValue);
    if (serial == null) {
      if (mounted) {
        setState(
          () => _errorText =
              'QR detected, but no sensor serial number was found.',
        );
      }
      return;
    }

    _handledScan = true;
    unawaited(HapticFeedback.selectionClick());
    Navigator.of(context).pop(rawValue);
  }
}

class WarmupCountdownScreen extends ConsumerWidget {
  const WarmupCountdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensor = ref.watch(selectedSensorProvider);
    final minutes = warmupMinutesRemaining(sensor);

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Step 3',
          title: 'Warm-up',
          subtitle: 'Your sensor is calibrating for accurate readings.',
        ),
        PremiumCard(
          color: AppColors.warningSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(
                label: 'WARMING UP',
                color: AppColors.warning,
                icon: Icons.hourglass_top_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '$minutes min',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.warning,
                ),
              ),
              Text(
                'Keep the phone near the sensor while first readings become available.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: minutes == 0
                        ? () {
                            ref
                                .read(appControllerProvider.notifier)
                                .finishWarmupNow();
                            context.push('/sensor/status');
                          }
                        : null,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      minutes == 0 ? 'Complete warm-up' : 'Warming up',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/sensor/status'),
                    icon: const Icon(Icons.info_outline_rounded),
                    label: const Text('Status'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SensorStatusScreen extends ConsumerWidget {
  const SensorStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensor = ref.watch(selectedSensorProvider);
    final appState = ref.watch(appControllerProvider);
    final daysLeft = sensorDaysRemaining(sensor);
    final batteryLevel = sensor?.batteryStatus ?? 100;
    final statusColor = sensor?.status == SensorStatus.active
        ? AppColors.success
        : sensor?.status == SensorStatus.warmingUp
        ? AppColors.warning
        : AppColors.primary;

    return AppScreen(
      children: [
        // Battery low warning
        if (batteryLevel < 20)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.battery_alert_rounded,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Sensor battery low ($batteryLevel%). Consider replacing soon.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SectionHeader(
          showBack: true,
          eyebrow: 'Sensor',
          title: 'Sensor status',
          subtitle: 'Current sensor health and connection details.',
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.wellness,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.wellness.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(
                label: sensor?.status.name.toUpperCase() ?? 'UNKNOWN',
                color: statusColor,
                icon: Icons.sensors_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                sensor?.serialNumber ?? '--',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                appState.cgmConnectionStatus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onDarkMuted,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final metrics = [
                    _SensorMetric(
                      label: 'Battery',
                      value: '${sensor?.batteryStatus ?? 0}%',
                    ),
                    _SensorMetric(label: 'Life', value: '${daysLeft}d'),
                    _SensorMetric(
                      label: 'Signal',
                      value: sensor?.connectionStatus.name ?? 'offline',
                    ),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: compact ? 1 : 3,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      mainAxisExtent: 72,
                    ),
                    itemBuilder: (context, index) =>
                        _SensorMetricCard(metric: metrics[index]),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Readiness checklist',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReadinessRow(
                icon: Icons.bluetooth_connected_rounded,
                label: 'Connection',
                value: sensor?.connectionStatus.name ?? 'offline',
                ready: sensor?.connectionStatus == ConnectionStatus.connected,
              ),
              _ReadinessRow(
                icon: Icons.hourglass_top_rounded,
                label: 'Warm-up',
                value: '${warmupMinutesRemaining(sensor)} min remaining',
                ready: warmupMinutesRemaining(sensor) == 0,
              ),
              _ReadinessRow(
                icon: Icons.monitor_heart_rounded,
                label: 'Data stream',
                value: appState.cgmConnected ? 'Live readings' : 'Preview data',
                ready: appState.cgmConnected,
                bottomPadding: 0,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.go('/readings'),
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('Open readings'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/devices'),
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('Devices'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SensorMetric {
  const _SensorMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _SensorMetricCard extends StatelessWidget {
  const _SensorMetricCard({required this.metric});

  final _SensorMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.onDark.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onDarkMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.onDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ready,
    this.bottomPadding = AppSpacing.md,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ready;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final color = ready ? AppColors.success : AppColors.warning;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          StatusPill(
            label: ready ? 'READY' : 'CHECK',
            color: color,
            icon: ready
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumCard(
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              child: Text(
                number,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
