package com.luis.ducky_android

import android.bluetooth.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.luis.ducky_android/hid"
    private val EVENT_CHANNEL = "com.luis.ducky_android/devices"
    private val discoveredDevices = mutableListOf<Map<String, String>>()
    private var eventSink: EventChannel.EventSink? = null

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE).toInt()
                    device?.let {
                        val name = it.name ?: "Unknown Device"
                        val address = it.address
                        val entry = mapOf("name" to name, "address" to address, "rssi" to rssi.toString())
                        if (discoveredDevices.none { d -> d["address"] == address }) {
                            discoveredDevices.add(entry)
                            runOnUiThread { eventSink?.success(entry) }
                        }
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    runOnUiThread { eventSink?.success(mapOf("scan_complete" to "true")) }
                }
                BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    // Let HidManager handle the actual state, we just notify Dart
                    runOnUiThread { eventSink?.success(mapOf("connection_state" to "disconnected")) }
                }
                BluetoothDevice.ACTION_ACL_CONNECTED -> {
                   // Optional: notify Dart if needed, though HidManager callback is better
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startClassicScan" -> {
                    startClassicScan()
                    result.success(true)
                }
                "stopClassicScan" -> {
                    stopClassicScan()
                    result.success(true)
                }
                "connectHid" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        result.success(HidManager.connect(address))
                    } else {
                        result.error("INVALID_ADDRESS", "Address is null", null)
                    }
                }
                "getBondedDevices" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    val bonded = adapter?.bondedDevices?.map {
                        mapOf("name" to (it.name ?: "Unknown"), "address" to it.address)
                    } ?: emptyList()
                    result.success(bonded)
                }
                "sendReport" -> {
                    val report = call.argument<ByteArray>("report")
                    if (report != null) {
                        result.success(HidManager.sendReport(report))
                    } else {
                        result.error("SEND_FAILED", "Null report", null)
                    }
                }
                "getConnectionStatus" -> {
                    result.success(HidManager.getStatus())
                }
                "setDiscoverable" -> {
                    val duration = call.argument<Int>("duration") ?: 300
                    setDiscoverable(duration)
                    result.success(true)
                }
                "unpairDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        result.success(unpairDevice(address))
                    } else {
                        result.error("INVALID_ADDRESS", "Address is null", null)
                    }
                }
                "disconnectHid" -> {
                    HidManager.disconnect()
                    result.success(true)
                }
                "initHidProfile" -> {
                    val deviceName = call.argument<String>("deviceName") ?: "Proximity Shark"
                    HidManager.initialize(this, deviceName)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
        }
        registerReceiver(bluetoothReceiver, filter)
        
        // Initial setup
        HidManager.initialize(this, "Proximity Shark")
        HidManager.setStateCallback { device, state ->
            val status = if (state == BluetoothProfile.STATE_CONNECTED) "connected" else "disconnected"
            val entry = mutableMapOf<String, String>(
                "connection_state" to status
            )
            device?.let { 
                entry["address"] = it.address
                entry["name"] = it.name ?: "Unknown"
            }
            runOnUiThread { eventSink?.success(entry) }
        }
        startHidService()
    }

    private fun startClassicScan() {
        discoveredDevices.clear()
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter?.isDiscovering == true) adapter.cancelDiscovery()
        adapter?.startDiscovery()
    }

    private fun stopClassicScan() {
        BluetoothAdapter.getDefaultAdapter()?.cancelDiscovery()
    }

    private fun unpairDevice(address: String): Boolean {
        return try {
            val device = BluetoothAdapter.getDefaultAdapter().getRemoteDevice(address)
            val method = device.javaClass.getMethod("removeBond")
            method.invoke(device) as Boolean
        } catch (e: Exception) {
            false
        }
    }

    private fun setDiscoverable(duration: Int) {
        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
            putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, duration)
        }
        startActivity(intent)
    }

    private fun startHidService() {
        val intent = Intent(this, HidService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(bluetoothReceiver)
    }
}
