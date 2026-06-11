import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optimus_cgm_flutter/models/optimus_models.dart';
import 'package:optimus_cgm_flutter/state/app_state.dart';

void main() {
  group('AppController CGM connection state', () {
    test(
      'native scan does not mark the sensor connected before SDK success',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final controller = container.read(appControllerProvider.notifier);
        controller.startSensorActivation();
        controller.attachSensor();
        controller.scanAndConnectSensor(serialNumber: 'D115W66200387');

        final state = container.read(appControllerProvider);
        final sensor = container.read(selectedSensorProvider);

        expect(state.cgmSensorSn, 'D115W66200387');
        expect(state.cgmConnecting, isTrue);
        expect(state.cgmConnected, isFalse);
        expect(state.cgmConnectionStatus, 'Scanning for sensor');
        expect(sensor?.status, SensorStatus.attached);
        expect(sensor?.connectionStatus, ConnectionStatus.nearby);
      },
    );

    test('SDK success starts warm-up and marks connection established', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(appControllerProvider.notifier);
      controller.startSensorActivation();
      controller.attachSensor();
      controller.scanAndConnectSensor(serialNumber: 'D115W66200387');
      controller.setCgmConnectionState(
        status: 'Sensor connected',
        connected: true,
        connecting: false,
        sensorSn: 'D115W66200387',
      );

      final state = container.read(appControllerProvider);
      final sensor = container.read(selectedSensorProvider);

      expect(state.cgmConnecting, isFalse);
      expect(state.cgmConnected, isTrue);
      expect(sensor?.status, SensorStatus.warmingUp);
      expect(sensor?.connectionStatus, ConnectionStatus.connected);
      expect(sensor?.warmupStartTime, isNotNull);
      expect(sensor?.warmupEndTime, isNotNull);
    });
  });
}
