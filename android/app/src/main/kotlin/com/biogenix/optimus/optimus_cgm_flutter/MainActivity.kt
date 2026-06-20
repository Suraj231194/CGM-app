package com.biogenix.optimus.optimus_cgm_flutter

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanResult
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.annotation.RequiresPermission
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.eaglenos.blehealth.callback.CgmAuthCallback
import com.eaglenos.blehealth.callback.CgmConnectCallback
import com.eaglenos.blehealth.callback.CgmDeviceStateInfoCallback
import com.eaglenos.blehealth.callback.CgmPermissionCallback
import com.eaglenos.blehealth.callback.CgmScanCallback
import com.eaglenos.blehealth.callback.CgmSyncHistoryCallback
import com.eaglenos.blehealth.cgm.CgmDeviceManager
import com.eaglenos.blehealth.cgm.CgmPermissionHelper
import com.eaglenos.blehealth.entity.CgmBloodSugar
import com.eaglenos.blehealth.entity.CgmDeviceInfo
import com.eaglenos.blehealth.entity.CgmError
import com.eaglenos.blehealth.entity.DeviceAbnormalState
import com.eaglenos.blehealth.heartbeat.CgmHeartbeatCallback
import com.eaglenos.blehealth.heartbeat.CgmHeartbeatTimerUtil
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val bridge by lazy { CgmSdkBridge(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge.attach(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (!bridge.onRequestPermissionsResult(requestCode, permissions, grantResults)) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }
}

private class CgmSdkBridge(private val activity: MainActivity) {
    private val manager = CgmDeviceManager.getInstance()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var bleStateEventSink: EventChannel.EventSink? = null
    private var activeSn: String = ""
    private var pendingBluetoothPermissionResult: MethodChannel.Result? = null
    private var pendingCameraPermissionResult: MethodChannel.Result? = null
    private var connectTimeoutRunnable: Runnable? = null
    private var bluetoothReceiver: BroadcastReceiver? = null
    private var isConnecting: Boolean = false

    fun attach(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler(::handleMethodCall)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        eventSink = events
                        configureCallbacks()
                        sendEvent("ready", mapOf("connected" to manager.isConnected()))
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null
                    }
                },
            )
        // BLE state event channel for real-time Bluetooth adapter state changes
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BLE_STATE_CHANNEL)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        bleStateEventSink = events
                        registerBluetoothStateReceiver()
                        // Send initial state
                        val initialState = if (isBluetoothEnabled()) "poweredOn" else "poweredOff"
                        events?.success(mapOf("state" to initialState))
                    }

                    override fun onCancel(arguments: Any?) {
                        bleStateEventSink = null
                        unregisterBluetoothStateReceiver()
                    }
                },
            )
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "auth" -> auth(call, result)
            "checkAuthorized" -> result.success(manager.checkAuthorized())
            "requestBluetoothPermissions" -> requestBluetoothPermissions(result)
            "requestCameraPermission" -> requestCameraPermission(result)
            "openAppPermissionSettings" -> openAppPermissionSettings(result)
            "openBluetoothSettings" -> openBluetoothSettings(result)
            "requestBleAndBackgroundPermissions" -> requestBleAndBackgroundPermissions(result)
            "requestIgnoreBatteryOptimization" -> requestIgnoreBatteryOptimization(result)
            "isBluetoothEnabled" -> {
                result.success(isBluetoothEnabled())
            }
            "connect" -> connect(call, result)
            "disconnect" -> {
                connectTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
                connectTimeoutRunnable = null
                isConnecting = false
                manager.disconnectDevice()
                manager.stopScanBluetooth()
                result.success(null)
            }
            "isConnected" -> result.success(manager.isConnected())
            "getHistoryFromIndexStart" -> getHistoryFromIndexStart(call, result)
            "getHistoryFromTimeRange" -> getHistoryFromTimeRange(call, result)
            "startHeartbeat" -> startHeartbeat(result)
            "stopHeartbeat" -> {
                CgmHeartbeatTimerUtil.INSTANCE.stopHeartbeat()
                result.success(null)
            }
            "checkBluetoothPermissions" -> {
                result.success(if (hasRequiredBluetoothPermissions()) "granted" else "denied")
            }
            else -> result.notImplemented()
        }
    }

    private fun auth(call: MethodCall, result: MethodChannel.Result) {
        val appId = call.argument<String>("appId")
        val appSecret = call.argument<String>("appSecret")
        if (appId.isNullOrBlank() || appSecret.isNullOrBlank()) {
            result.error("invalid_auth", "appId and appSecret are required.", null)
            return
        }

        manager.authCert(
            appId,
            appSecret,
            object : CgmAuthCallback {
                override fun onSuccess() {
                    sendEvent("authSuccess")
                    mainHandler.post { result.success(true) }
                }

                override fun onError(error: CgmError?) {
                    val payload = error.toMap()
                    sendEvent("authError", payload)
                    mainHandler.post {
                        result.error("auth_failed", error?.message ?: "SDK authentication failed.", payload)
                    }
                }
            },
        )
    }

    private fun requestBluetoothPermissions(result: MethodChannel.Result) {
        if (hasRequiredBluetoothPermissions()) {
            result.success("granted")
            return
        }

        if (pendingBluetoothPermissionResult != null) {
            result.error("permission_request_active", "A Bluetooth permission request is already active.", null)
            return
        }

        val permissions = requiredBluetoothPermissions()
            .filterNot(::isPermissionGranted)
            .toTypedArray()

        if (permissions.isEmpty()) {
            result.success("granted")
            return
        }

        pendingBluetoothPermissionResult = result
        ActivityCompat.requestPermissions(
            activity,
            permissions,
            REQUEST_BLUETOOTH_PERMISSIONS,
        )
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (isPermissionGranted(Manifest.permission.CAMERA)) {
            result.success("granted")
            return
        }

        if (pendingCameraPermissionResult != null) {
            result.error("permission_request_active", "A camera permission request is already active.", null)
            return
        }

        pendingCameraPermissionResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.CAMERA),
            REQUEST_CAMERA_PERMISSION,
        )
    }

    private fun openAppPermissionSettings(result: MethodChannel.Result) {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", activity.packageName, null),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        activity.startActivity(intent)
        result.success(null)
    }

    private fun openBluetoothSettings(result: MethodChannel.Result) {
        val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        activity.startActivity(intent)
        result.success(null)
    }

    private fun requestBleAndBackgroundPermissions(result: MethodChannel.Result) {
        CgmPermissionHelper(activity).requestBleAndBackgroundPermission(permissionCallback(result))
    }

    private fun requestIgnoreBatteryOptimization(result: MethodChannel.Result) {
        CgmPermissionHelper(activity).requestIgnoreBatteryOptimization(permissionCallback(result))
    }

    private fun permissionCallback(result: MethodChannel.Result): CgmPermissionCallback {
        return object : CgmPermissionCallback {
            override fun onAllGranted() {
                sendEvent("permissions", mapOf("status" to "granted"))
                mainHandler.post { result.success("granted") }
            }

            override fun onDenied() {
                sendEvent("permissions", mapOf("status" to "denied"))
                mainHandler.post { result.success("denied") }
            }

            override fun onPermanentlyDenied() {
                sendEvent("permissions", mapOf("status" to "permanentlyDenied"))
                mainHandler.post { result.success("permanentlyDenied") }
            }
        }
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            val result = pendingCameraPermissionResult ?: return true
            pendingCameraPermissionResult = null

            val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
            val status = when {
                granted -> "granted"
                !ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.CAMERA) -> "permanentlyDenied"
                else -> "denied"
            }
            mainHandler.post { result.success(status) }
            return true
        }

        if (requestCode != REQUEST_BLUETOOTH_PERMISSIONS) return false

        val result = pendingBluetoothPermissionResult ?: return true
        pendingBluetoothPermissionResult = null

        val deniedPermissions = if (grantResults.isEmpty()) {
            permissions.toList()
        } else {
            permissions.filterIndexed { index, _ ->
                grantResults.getOrNull(index) != PackageManager.PERMISSION_GRANTED
            }
        }

        val status = when {
            deniedPermissions.isEmpty() -> "granted"
            deniedPermissions.any { !ActivityCompat.shouldShowRequestPermissionRationale(activity, it) } -> "permanentlyDenied"
            else -> "denied"
        }

        sendEvent("permissions", mapOf("status" to status))
        mainHandler.post { result.success(status) }
        return true
    }

    private fun requiredBluetoothPermissions(): List<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
            )
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    private fun isPermissionGranted(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasRequiredBluetoothPermissions(): Boolean {
        return requiredBluetoothPermissions().all(::isPermissionGranted)
    }

    private fun isBluetoothEnabled(): Boolean {
        return try {
            val btManager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            btManager?.adapter?.isEnabled == true
        } catch (_: SecurityException) {
            false
        }
    }

    private fun connect(call: MethodCall, result: MethodChannel.Result) {
        val sn = call.argument<String>("sn")
        if (sn.isNullOrBlank()) {
            result.error("invalid_sn", "Sensor SN is required.", null)
            return
        }
        if (!hasRequiredBluetoothPermissions()) {
            result.error(
                "bluetooth_permission_required",
                "Bluetooth scan/connect permission is required before scanning.",
                mapOf("status" to "permissionRequired", "sn" to sn),
            )
            return
        }
        // Guard against concurrent connection attempts
        if (isConnecting) {
            result.error(
                "connect_in_progress",
                "A connection attempt is already in progress.",
                mapOf("sn" to sn),
            )
            return
        }
        if (!isBluetoothEnabled()) {
            result.error(
                "bluetooth_disabled",
                "Bluetooth is turned off. Please enable Bluetooth.",
                mapOf("sn" to sn),
            )
            sendEvent("bleState", mapOf("state" to "poweredOff", "poweredOn" to false))
            return
        }

        isConnecting = true
        activeSn = sn
        val autoConnect = call.argument<Boolean>("autoConnect") ?: false
        sendEvent("connection", mapOf("status" to "scanning", "sn" to sn))

        var resultSent = false
        val timeoutRunnable = Runnable {
            if (!resultSent) {
                resultSent = true
                isConnecting = false
                connectTimeoutRunnable = null
                manager.stopScanBluetooth()
                sendEvent("connection", mapOf("status" to "timeout", "sn" to sn, "message" to "Connection timed out. Ensure sensor is nearby."))
                result.error("connect_timeout", "Sensor connection timed out after 30 seconds.", null)
            }
        }
        connectTimeoutRunnable = timeoutRunnable
        mainHandler.postDelayed(timeoutRunnable, 30_000L)

        manager.connectTargetAndStartScan(
            sn,
            autoConnect,
            object : CgmConnectCallback {
                override fun onDeviceDisconnected() {
                    // Only treat as a real disconnect if the initial connection
                    // was already resolved (resultSent == true means we were
                    // connected and now disconnected). If resultSent is false,
                    // this is just a transient event during scanning/connecting.
                    if (resultSent) {
                        isConnecting = false
                        sendEvent("connection", mapOf("status" to "disconnected", "sn" to activeSn))
                    }
                }

                override fun onSuccess() {
                    mainHandler.removeCallbacks(timeoutRunnable)
                    connectTimeoutRunnable = null
                    isConnecting = false
                    if (!resultSent) {
                        resultSent = true
                        manager.stopScanBluetooth()
                        sendEvent("connection", mapOf("status" to "connected", "sn" to activeSn))
                        mainHandler.post { result.success(true) }
                    }
                }

                override fun onFailure(error: CgmError?) {
                    mainHandler.removeCallbacks(timeoutRunnable)
                    connectTimeoutRunnable = null
                    isConnecting = false
                    if (!resultSent) {
                        resultSent = true
                        val payload = error.toMap() + mapOf("status" to "failed", "sn" to activeSn)
                        sendEvent("connection", payload)
                        mainHandler.post {
                            result.error("connect_failed", error?.message ?: "CGM connection failed.", payload)
                        }
                    }
                }
            },
        )
    }

    private fun startHeartbeat(result: MethodChannel.Result) {
        if (activeSn.isBlank()) {
            result.error("missing_sn", "Connect once or pass a sensor SN before starting heartbeat.", null)
            return
        }
        if (!hasRequiredBluetoothPermissions()) {
            result.error(
                "bluetooth_permission_required",
                "Bluetooth scan/connect permission is required before heartbeat scanning.",
                null,
            )
            return
        }

        CgmHeartbeatTimerUtil.INSTANCE.startHeartbeat(
            activity.applicationContext,
            object : CgmHeartbeatCallback {
                override fun onHeartbeatStart() {
                    sendEvent("heartbeat", mapOf("status" to "start"))
                    manager.startScanBluetooth(
                        object : CgmScanCallback {
                            @RequiresPermission(android.Manifest.permission.BLUETOOTH_CONNECT)
                            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
                                manager.connectTargetDevice(scanResult, activeSn, false, reconnectCallback)
                            }

                            override fun onScanFailed(errorCode: Int, message: String?) {
                                sendEvent(
                                    "scanFailed",
                                    mapOf("code" to errorCode, "message" to (message ?: "")),
                                )
                            }
                        },
                    )
                }

                override fun onHeartbeatStop() {
                    sendEvent("heartbeat", mapOf("status" to "stop"))
                    manager.stopScanBluetooth()
                }
            },
        )
        result.success(null)
    }

    private val reconnectCallback =
        object : CgmConnectCallback {
            override fun onDeviceDisconnected() {
                sendEvent("connection", mapOf("status" to "disconnected", "sn" to activeSn))
            }

            override fun onSuccess() {
                manager.stopScanBluetooth()
                sendEvent("connection", mapOf("status" to "reconnected", "sn" to activeSn))
            }

            override fun onFailure(error: CgmError?) {
                sendEvent("connection", error.toMap() + mapOf("status" to "reconnectFailed", "sn" to activeSn))
            }
        }

    private fun getHistoryFromIndexStart(call: MethodCall, result: MethodChannel.Result) {
        val sn = call.argument<String>("sn") ?: activeSn
        val indexStart = call.argument<Int>("indexStart") ?: 1
        if (sn.isBlank()) {
            result.error("invalid_sn", "Sensor SN is required.", null)
            return
        }

        manager.getHistoryFromIndexStart(
            sn,
            indexStart,
            object : CgmSyncHistoryCallback {
                override fun onSyncHistorySuccess(data: List<CgmBloodSugar>?) {
                    mainHandler.post { result.success(data.orEmpty().map { it.toMap() }) }
                }

                override fun onSyncHistoryFailed(error: CgmError?) {
                    val payload = error.toMap()
                    mainHandler.post {
                        result.error("history_failed", error?.message ?: "History sync failed.", payload)
                    }
                }
            },
        )
    }

    private fun getHistoryFromTimeRange(call: MethodCall, result: MethodChannel.Result) {
        val sn = call.argument<String>("sn") ?: activeSn
        val startTime = call.argument<Number>("startTime")?.toLong() ?: 0L
        val endTime = call.argument<Number>("endTime")?.toLong() ?: 0L
        if (sn.isBlank()) {
            result.error("invalid_sn", "Sensor SN is required.", null)
            return
        }

        manager.getHistoryFromTimeRange(
            sn,
            startTime,
            endTime,
            object : CgmSyncHistoryCallback {
                override fun onSyncHistorySuccess(data: List<CgmBloodSugar>?) {
                    mainHandler.post { result.success(data.orEmpty().map { it.toMap() }) }
                }

                override fun onSyncHistoryFailed(error: CgmError?) {
                    val payload = error.toMap()
                    mainHandler.post {
                        result.error("history_failed", error?.message ?: "History sync failed.", payload)
                    }
                }
            },
        )
    }

    private fun configureCallbacks() {
        manager.setCgmLogCallback { message ->
            sendEvent("log", mapOf("message" to message))
        }
        manager.setCgmBindStepCallback { step ->
            sendEvent("bindStep", mapOf("step" to step.name))
        }
        manager.setCgmDeviceDataSyncProgressCallback { progress ->
            sendEvent("syncProgress", mapOf("progress" to progress))
        }
        manager.setCgmDeviceStateInfoCallback(
            object : CgmDeviceStateInfoCallback {
                override fun onFailed(error: CgmError?) {
                    sendEvent("sdkError", error.toMap())
                }

                override fun onGlucoseDataWithErrorReceived(
                    isAbandoned: Boolean,
                    isErrorShow: Boolean,
                    abnormalStates: List<DeviceAbnormalState>?,
                    bloodSugars: List<CgmBloodSugar>?,
                ) {
                    sendEvent(
                        "glucoseData",
                        mapOf(
                            "isAbandoned" to isAbandoned,
                            "isErrorShow" to isErrorShow,
                            "abnormalStates" to abnormalStates.orEmpty().map { it.name },
                            "readings" to bloodSugars.orEmpty().map { it.toMap() },
                        ),
                    )
                }

                override fun onDeviceInfoReceived(info: CgmDeviceInfo?) {
                    sendEvent("deviceInfo", info.toMap())
                }
            },
        )
    }

    private fun sendEvent(type: String, data: Map<String, Any?> = emptyMap()) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to type, "data" to data))
        }
    }

    private fun registerBluetoothStateReceiver() {
        if (bluetoothReceiver != null) return
        bluetoothReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action != BluetoothAdapter.ACTION_STATE_CHANGED) return
                val btState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                val stateStr = when (btState) {
                    BluetoothAdapter.STATE_ON -> "poweredOn"
                    BluetoothAdapter.STATE_OFF -> "poweredOff"
                    BluetoothAdapter.STATE_TURNING_OFF -> "poweredOff"
                    BluetoothAdapter.STATE_TURNING_ON -> "resetting"
                    else -> "unknown"
                }
                mainHandler.post {
                    bleStateEventSink?.success(mapOf("state" to stateStr))
                }
                // Also emit on the main event channel for backward compatibility
                val poweredOn = btState == BluetoothAdapter.STATE_ON
                sendEvent("bleState", mapOf("state" to stateStr, "poweredOn" to poweredOn))

                // If BT was turned off during scan/connection, abort immediately
                if (btState == BluetoothAdapter.STATE_OFF || btState == BluetoothAdapter.STATE_TURNING_OFF) {
                    if (isConnecting) {
                        connectTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
                        connectTimeoutRunnable = null
                        isConnecting = false
                        manager.stopScanBluetooth()
                        sendEvent("connection", mapOf(
                            "status" to "failed",
                            "sn" to activeSn,
                            "message" to "Bluetooth was turned off during connection.",
                        ))
                    }
                }
            }
        }
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        activity.registerReceiver(bluetoothReceiver, filter)
    }

    private fun unregisterBluetoothStateReceiver() {
        bluetoothReceiver?.let {
            try {
                activity.unregisterReceiver(it)
            } catch (_: Exception) {}
        }
        bluetoothReceiver = null
    }

    companion object {
        private const val METHOD_CHANNEL = "optimus_cgm/sdk"
        private const val EVENT_CHANNEL = "optimus_cgm/sdk_events"
        private const val BLE_STATE_CHANNEL = "optimus_cgm/ble_state"
        private const val REQUEST_BLUETOOTH_PERMISSIONS = 4101
        private const val REQUEST_CAMERA_PERMISSION = 4102
    }
}

private fun CgmError?.toMap(): Map<String, Any?> {
    if (this == null) return mapOf("name" to "unknown", "message" to "Unknown error")
    return mapOf("name" to name, "message" to message)
}

private fun CgmBloodSugar.toMap(): Map<String, Any?> {
    return mapOf(
        "originalBloodSugar" to originalBloodSugar,
        "processedBloodSugar" to processedBloodSugar,
        "connectCode" to connectCode,
        "createTime" to createTime,
        "timeOffset" to timeOffset,
        "measurementStatus" to measurementStatus,
        "current" to current,
        "temperature" to temperature,
        "batteryVoltage" to batteryVoltage,
        "trend" to trend,
    )
}

private fun CgmDeviceInfo?.toMap(): Map<String, Any?> {
    if (this == null) return emptyMap()
    return mapOf(
        "measurementInterval" to measurementInterval,
        "firmwareVersion" to firmwareVersion,
        "deviceActivateTimestamp" to deviceActivateTimestamp,
        "timeOffset" to timeOffset,
        "isPreheating" to isPreheating,
        "isInUse" to isInUse,
        "isExpired" to isExpired,
        "isDeviceReset" to isDeviceReset,
        "abnormalStates" to abnormalStates.orEmpty().map { it.name },
    )
}
