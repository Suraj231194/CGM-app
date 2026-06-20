import AVFoundation
import CoreBluetooth
import Flutter
import Foundation
import StayOnFramework
import UIKit

final class CgmSdkIosBridge: NSObject, FlutterStreamHandler, CBCentralManagerDelegate {
  static let shared = CgmSdkIosBridge()

  private var eventSink: FlutterEventSink?
  private var bleStateEventSink: FlutterEventSink?
  private var callbacksRegistered = false
  private var authorized = false
  private var connected = false
  private var isConnecting = false
  private var currentSensorSn: String?
  private var cachedReadings: [[String: Any]] = []
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private var bleStateChannel: FlutterEventChannel?
  private lazy var centralManager: CBCentralManager = {
    return CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
  }()

  private override init() {
    super.init()
  }

  // MARK: - CBCentralManagerDelegate
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let stateStr: String
    switch central.state {
    case .poweredOn:
      stateStr = "poweredOn"
    case .poweredOff:
      stateStr = "poweredOff"
    case .unauthorized:
      stateStr = "unauthorized"
    case .resetting:
      stateStr = "resetting"
    case .unsupported:
      stateStr = "unsupported"
    case .unknown:
      stateStr = "unknown"
    @unknown default:
      stateStr = "unknown"
    }

    DispatchQueue.main.async { [weak self] in
      self?.bleStateEventSink?(["state": stateStr])
    }

    // Emit on main SDK event channel for backward compat
    let poweredOn = central.state == .poweredOn
    emit("bleState", [
      "state": stateStr,
      "poweredOn": poweredOn,
    ])

    // If BT turned off during connection, abort immediately
    if central.state == .poweredOff && isConnecting {
      isConnecting = false
      connected = false
      if let pending = pendingConnectResult {
        pendingConnectResult = nil
        DispatchQueue.main.async { pending(false) }
      }
      emit("connection", [
        "connected": false,
        "sn": currentSensorSn ?? "",
        "message": "Bluetooth was turned off during connection.",
        "status": "failed",
      ])
    }
  }

  func register(with messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: "optimus_cgm/sdk",
      binaryMessenger: messenger
    )
    methodChannel?.setMethodCallHandler(handle)

    eventChannel = FlutterEventChannel(
      name: "optimus_cgm/sdk_events",
      binaryMessenger: messenger
    )
    eventChannel?.setStreamHandler(self)

    bleStateChannel = FlutterEventChannel(
      name: "optimus_cgm/ble_state",
      binaryMessenger: messenger
    )
    bleStateChannel?.setStreamHandler(BleStateStreamHandler(bridge: self))

    // Trigger centralManager initialization to start receiving delegate callbacks
    _ = centralManager

    registerCallbacksIfNeeded()
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    registerCallbacksIfNeeded()
    emit("ready", [
      "platform": "ios",
      "message": "Native iOS CGM bridge is ready.",
      "version": SOFCGMManager.shared.fullVersion,
    ])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "auth":
      auth(args: args, result: result)
    case "checkAuthorized":
      result(authorized)
    case "requestBluetoothPermissions", "requestBleAndBackgroundPermissions":
      let authStatus: String
      if #available(iOS 13.1, *) {
        switch CBManager.authorization {
        case .allowedAlways:
          authStatus = "granted"
        case .denied:
          authStatus = "denied"
        case .restricted:
          authStatus = "denied"
        case .notDetermined:
          authStatus = "ios-managed"
        @unknown default:
          authStatus = "ios-managed"
        }
      } else {
        authStatus = "ios-managed"
      }
      emit("permissions", [
        "status": authStatus,
        "message": "iOS Bluetooth authorization: \(authStatus). System will prompt when scanning starts.",
      ])
      result(authStatus)
    case "requestIgnoreBatteryOptimization":
      result("not-applicable")
    case "requestCameraPermission":
      let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
      switch cameraStatus {
      case .authorized:
        result("granted")
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async {
            result(granted ? "granted" : "denied")
          }
        }
      case .denied:
        result("permanentlyDenied")
      case .restricted:
        result("denied")
      @unknown default:
        result("error")
      }
    case "openAppPermissionSettings":
      if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        DispatchQueue.main.async {
          UIApplication.shared.open(settingsUrl)
        }
      }
      result(nil)
    case "openBluetoothSettings":
      if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        DispatchQueue.main.async {
          UIApplication.shared.open(settingsUrl)
        }
      }
      result(nil)
    case "connect":
      connect(args: args, result: result)
    case "disconnect":
      isConnecting = false
      SOFCGMManager.shared.disconnect()
      connected = false
      emit("connection", [
        "connected": false,
        "sn": currentSensorSn ?? "",
        "message": "Sensor disconnected.",
      ])
      result(nil)
    case "isConnected":
      result(connected)
    case "isBluetoothEnabled":
      result(centralManager.state == .poweredOn)
    case "checkBluetoothPermissions":
      let authStatus: String
      if #available(iOS 13.1, *) {
        switch CBManager.authorization {
        case .allowedAlways:
          authStatus = "granted"
        case .denied:
          authStatus = "denied"
        case .restricted:
          authStatus = "denied"
        case .notDetermined:
          authStatus = "ios-managed"
        @unknown default:
          authStatus = "ios-managed"
        }
      } else {
        authStatus = "ios-managed"
      }
      result(authStatus)
    case "getHistoryFromIndexStart":
      let start = intValue(args["indexStart"])
      SOFCGMManager.shared.getHistoryData(package_num: start)
      result(cachedReadings.filter { intValue($0["timeOffset"]) >= start })
    case "getHistoryFromTimeRange":
      let start = intValue(args["startTime"])
      let end = intValue(args["endTime"])
      result(
        cachedReadings.filter {
          let createTime = intValue($0["createTime"])
          return createTime >= start && createTime <= end
        }
      )
    case "startHeartbeat":
      emit("heartbeat", ["enabled": true, "message": "iOS SDK callbacks active."])
      result(nil)
    case "stopHeartbeat":
      emit("heartbeat", ["enabled": false, "message": "iOS SDK callbacks remain managed by the framework."])
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func auth(args: [String: Any], result: @escaping FlutterResult) {
    guard
      let appId = args["appId"] as? String,
      let appSecret = args["appSecret"] as? String,
      !appId.isEmpty,
      !appSecret.isEmpty
    else {
      result(false)
      return
    }

    SOFCGMManager.shared.auth(appid: appId, appsecrect: appSecret) { [weak self] error in
      DispatchQueue.main.async {
        guard let self = self else { return }
        if let error = error {
          self.authorized = false
          self.emit("authError", [
            "code": error.code,
            "message": error.localizedDescription,
          ])
          result(false)
        } else {
          self.authorized = true
          self.emit("authSuccess", ["message": "SDK authorization completed."])
          result(true)
        }
      }
    }
  }

  private var pendingConnectResult: FlutterResult?

  private func connect(args: [String: Any], result: @escaping FlutterResult) {
    guard let sn = args["sn"] as? String, !sn.isEmpty else {
      result(false)
      return
    }

    // Guard against concurrent connection attempts
    if isConnecting {
      result(false)
      return
    }

    // Check Bluetooth state before attempting
    if centralManager.state != .poweredOn {
      emit("bleState", [
        "state": "poweredOff",
        "poweredOn": false,
      ])
      result(false)
      return
    }

    isConnecting = true
    currentSensorSn = sn
    pendingConnectResult = result
    let packageNumber = intValue(args["packageNum"])
    emit("connection", [
      "connected": false,
      "sn": sn,
      "message": "Sensor connection started.",
    ])
    SOFCGMManager.shared.connect(sn: sn, package_num: packageNumber)

    // Timeout: if connection doesn't succeed within 30s, return false
    DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
      guard let self = self, let pending = self.pendingConnectResult else { return }
      self.pendingConnectResult = nil
      self.isConnecting = false
      if !self.connected {
        self.emit("connection", [
          "connected": false,
          "sn": sn,
          "message": "Connection timed out.",
          "status": "timeout",
        ])
        pending(false)
      }
    }
  }

  private func registerCallbacksIfNeeded() {
    guard !callbacksRegistered else { return }
    callbacksRegistered = true

    SOFCGMManager.shared.addCallback { [weak self] state in
      self?.emit("bleState", [
        "state": state.rawValue,
        "poweredOn": state == .poweredOn,
      ])
    } cgmConState: { [weak self] state in
      guard let self = self else { return }
      self.connected = state == .connected
      if state == .connected || state == .disconnected {
        self.isConnecting = false
      }
      self.emit("connection", [
        "connected": self.connected,
        "sn": self.currentSensorSn ?? "",
        "state": state.rawValue,
        "status": state == .connected ? "connected" : state == .disconnected ? "disconnected" : "connecting",
        "message": self.connectionStateText(state),
      ])
      // Resolve pending connect result
      if state == .connected, let pending = self.pendingConnectResult {
        self.pendingConnectResult = nil
        DispatchQueue.main.async { pending(true) }
      } else if state == .disconnected, let pending = self.pendingConnectResult {
        self.pendingConnectResult = nil
        DispatchQueue.main.async { pending(false) }
      }
    } cgmConProcessState: { [weak self] state in
      self?.emit("bindStep", [
        "step": state.rawValue,
        "message": self?.connectionProcessText(state) ?? "Connection step updated.",
      ])
    } cgmDevInfo: { [weak self] info in
      self?.emit("deviceInfo", self?.deviceInfoMap(info) ?? [:])
    } cgmDevData: { [weak self] data in
      guard let self = self else { return }
      let readings = data.dataList.map { self.readingMap($0) }
      self.cachedReadings.append(contentsOf: readings)
      self.cachedReadings = self.deduplicate(self.cachedReadings)
      self.emit("deviceInfo", [
        "sensorState": data.sensorState.rawValue,
        "isPreheating": data.sensorState == .warmingUp,
        "isInUse": data.sensorState == .active,
        "isExpired": data.sensorState == .expired || data.sensorState == .failureAlarm || data.sensorState == .failureReset,
      ])
      self.emit("glucoseData", ["readings": readings])
    } cgmHistoryDataProgress: { [weak self] progress in
      self?.emit("syncProgress", [
        "progress": Int(progress * 100),
        "message": "History sync progress updated.",
      ])
    } failure: { [weak self] error in
      self?.connected = false
      self?.emit("sdkError", [
        "code": error.code,
        "message": error.localizedDescription,
      ])
    }
  }

  private func emit(_ type: String, _ data: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(["type": type, "data": data])
    }
  }

  private func deviceInfoMap(_ info: SOCGMDeviceInfo) -> [String: Any] {
    return [
      "sensorState": info.sensorState.rawValue,
      "isPreheating": info.sensorState == .warmingUp,
      "isInUse": info.sensorState == .active,
      "isExpired": info.sensorState == .expired || info.sensorState == .failureAlarm || info.sensorState == .failureReset,
      "maxPacketID": info.maxPacketID,
      "measurementInterval": info.measurementInterval,
      "sensorStartTime": info.sensorStartTime,
      "firmwareVersion": info.firmwareVersion,
      "resetCode": info.resetCode.rawValue,
    ]
  }

  private func readingMap(_ model: SOFBloodSugarModel) -> [String: Any] {
    return [
      "sn": model.sn,
      "trend": intValue(model.trend),
      "type": intValue(model.type),
      "createTime": model.createTime,
      "timeOffset": model.packageNum,
      "bloodSugar": doubleValue(model.bloodSugar),
      "originalBloodSugar": doubleValue(model.originalBloodSugar),
      "processedBloodSugar": doubleValue(model.processedBloodSugar),
      "current": doubleValue(model.current),
      "temperature": doubleValue(model.temperature),
      "batteryVoltage": doubleValue(model.voltage),
      "measurementStatus": model.alarmCodeRawArr.first?.intValue ?? 0,
      "alarmCodes": model.alarmCodeRawArr.map { $0.intValue },
    ]
  }

  private func deduplicate(_ readings: [[String: Any]]) -> [[String: Any]] {
    var seen = Set<String>()
    return readings.filter { reading in
      let key = "\(reading["sn"] ?? "")-\(reading["createTime"] ?? "")-\(reading["timeOffset"] ?? "")"
      return seen.insert(key).inserted
    }
  }

  private func connectionStateText(_ state: SOBleDeviceConnectionState) -> String {
    switch state {
    case .connected:
      return "Sensor connected."
    case .connecting:
      return "Sensor connecting."
    case .disconnecting:
      return "Sensor disconnecting."
    case .disconnected:
      return "Sensor disconnected."
    @unknown default:
      return "Sensor connection state changed."
    }
  }

  private func connectionProcessText(_ state: SOCGMConProcessState) -> String {
    switch state {
    case .scan:
      return "Scanning for sensor."
    case .connect:
      return "Bluetooth connected."
    case .didDiscoverServices:
      return "Services discovered."
    case .didDiscoverCharacteristicsFor:
      return "Characteristics discovered."
    case .completed:
      return "Connection complete, syncing data."
    case .disConnect:
      return "Connection closed."
    case .didDisconnectPeripheral:
      return "Peripheral disconnected."
    @unknown default:
      return "Connection step updated."
    }
  }

  private func intValue(_ value: Any?) -> Int {
    if let value = value as? Int { return value }
    if let value = value as? NSNumber { return value.intValue }
    if let value = value as? String { return Int(value) ?? 0 }
    return 0
  }

  private func doubleValue(_ value: String?) -> Double {
    return Double(value ?? "") ?? 0
  }

  // Used by the BleStateStreamHandler to set the sink
  fileprivate func setBleStateEventSink(_ sink: FlutterEventSink?) {
    bleStateEventSink = sink
  }

  fileprivate func currentBleState() -> String {
    switch centralManager.state {
    case .poweredOn:
      return "poweredOn"
    case .poweredOff:
      return "poweredOff"
    case .unauthorized:
      return "unauthorized"
    case .resetting:
      return "resetting"
    case .unsupported:
      return "unsupported"
    case .unknown:
      return "unknown"
    @unknown default:
      return "unknown"
    }
  }
}

/// Separate stream handler for the BLE state event channel.
private class BleStateStreamHandler: NSObject, FlutterStreamHandler {
  private weak var bridge: CgmSdkIosBridge?

  init(bridge: CgmSdkIosBridge) {
    self.bridge = bridge
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    bridge?.setBleStateEventSink(events)
    // Send initial state
    let initialState = bridge?.currentBleState() ?? "unknown"
    events(["state": initialState])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    bridge?.setBleStateEventSink(nil)
    return nil
  }
}
