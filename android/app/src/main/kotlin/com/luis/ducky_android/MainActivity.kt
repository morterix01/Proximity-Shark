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
    private var bluetoothHidDevice: BluetoothHidDevice? = null
    private var targetDevice: BluetoothDevice? = null
    private val discoveredDevices = mutableListOf<Map<String, String>>()
    private var eventSink: EventChannel.EventSink? = null

    // Standard HID Keyboard Descriptor
    private val HID_DESCRIPTOR = byteArrayOf(
        0x05.toByte(), 0x01.toByte(),
        0x09.toByte(), 0x06.toByte(),
        0xA1.toByte(), 0x01.toByte(),
        0x05.toByte(), 0x07.toByte(),
        0x19.toByte(), 0xE0.toByte(),
        0x29.toByte(), 0xE7.toByte(),
        0x15.toByte(), 0x00.toByte(),
        0x25.toByte(), 0x01.toByte(),
        0x75.toByte(), 0x01.toByte(),
        0x95.toByte(), 0x08.toByte(),
        0x81.toByte(), 0x02.toByte(),
        0x95.toByte(), 0x01.toByte(),
        0x75.toByte(), 0x08.toByte(),
        0x81.toByte(), 0x01.toByte(),
        0x95.toByte(), 0x05.toByte(),
        0x75.toByte(), 0x01.toByte(),
        0x05.toByte(), 0x08.toByte(),
        0x19.toByte(), 0x01.toByte(),
        0x29.toByte(), 0x05.toByte(),
        0x91.toByte(), 0x02.toByte(),
        0x95.toByte(), 0x01.toByte(),
        0x75.toByte(), 0x03.toByte(),
        0x91.toByte(), 0x01.toByte(),
        0x95.toByte(), 0x06.toByte(),
        0x75.toByte(), 0x08.toByte(),
        0x15.toByte(), 0x00.toByte(),
        0x25.toByte(), 0x65.toByte(),
        0x05.toByte(), 0x07.toByte(),
        0x19.toByte(), 0x00.toByte(),
        0x29.toByte(), 0x65.toByte(),
        0x81.toByte(), 0x00.toByte(),
        0xC0.toByte()
    )

    private var pendingDeviceName: String? = null

    // BroadcastReceiver for Classic Bluetooth Discovery
    private val discoveryReceiver = object : BroadcastReceiver() {
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
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel: streams discovered devices to Dart
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

        // MethodChannel: commands from Dart
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
                        connectHid(address)
                        result.success(true)
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
                    if (report != null && bluetoothHidDevice != null && targetDevice != null) {
                        val sent = bluetoothHidDevice!!.sendReport(targetDevice!!, 1, report)
                        result.success(sent)
                    } else {
                        result.error("SEND_FAILED", "Not connected or null report", null)
                    }
                }
                "getConnectionStatus" -> {
                    result.success(if (targetDevice != null) 1 else 0)
                }
                "setDeviceName" -> {
                    val name = call.argument<String>("name")
                    if (name != null) {
                        result.success(setBluetoothName(name))
                    } else {
                        result.error("INVALID_NAME", "Name is null", null)
                    }
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
                    disconnectHid()
                    result.success(true)
                }
                "initHidProfile" -> {
                    val deviceName = call.argument<String>("deviceName") ?: "SharkHID"
                    initHidProfile(deviceName)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Register discovery receiver
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }
        registerReceiver(discoveryReceiver, filter)

        // Register HID profile
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        bluetoothAdapter?.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                if (profile == BluetoothProfile.HID_DEVICE) {
                    bluetoothHidDevice = proxy as BluetoothHidDevice
                    Log.d("HID", "HID Profile proxy connected. Waiting for initHidProfile from Dart...")
                    pendingDeviceName?.let { name ->
                        doRegister(name)
                    }
                }
            }
            override fun onServiceDisconnected(profile: Int) {
                if (profile == BluetoothProfile.HID_DEVICE) {
                    bluetoothHidDevice = null
                }
            }
        }, BluetoothProfile.HID_DEVICE)
    }


    private var retryCount = 0

    private fun initHidProfile(deviceName: String) {
        setBluetoothName(deviceName)
        pendingDeviceName = deviceName

        if (bluetoothHidDevice != null) {
            doRegister(deviceName)
        } else {
            Log.d("HID", "Proxy not ready yet, waiting for onServiceConnected...")
        }
    }

    private fun doRegister(name: String) {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter == null || !adapter.isEnabled) {
            Log.e("HID", "Cannot register HID: Bluetooth is OFF or null")
            runOnUiThread {
                android.widget.Toast.makeText(this@MainActivity, "⚠️ TURN BLUETOOTH ON FIRST!", android.widget.Toast.LENGTH_LONG).show()
            }
            return
        }

        if (bluetoothHidDevice == null) {
            Log.e("HID", "Cannot register HID: Proxy was null")
            return
        }

        Log.d("HID", "Starting clean registration cycle with delay...")
        try {
            // Unregister first to clear any stale state
            bluetoothHidDevice?.unregisterApp()
        } catch (e: Exception) {
            Log.w("HID", "Unregister failed (normal): ${e.message}")
        }

        val sdp = BluetoothHidDeviceAppSdpSettings(
            "Shark Board",
            "Android HID Keyboard",
            "Shark",
            BluetoothHidDevice.SUBCLASS1_KEYBOARD,
            HID_DESCRIPTOR
        )

        // Wait 800ms for system to finalize unregistration before registering again
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            Log.d("HID", "Invoking registerApp after delay...")
            bluetoothHidDevice?.registerApp(sdp, null, null, { it.run() }, object : BluetoothHidDevice.Callback() {
                override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
                    Log.d("HID", "HID Registration Callback: $registered")
                    runOnUiThread {
                        if (registered) {
                            retryCount = 0 // Reset on success
                            android.widget.Toast.makeText(this@MainActivity, "HID Profile Ready ✓", android.widget.Toast.LENGTH_SHORT).show()
                        } else {
                            if (retryCount < 1) {
                                retryCount++
                                android.widget.Toast.makeText(this@MainActivity, "Retry registration in 2s...", android.widget.Toast.LENGTH_SHORT).show()
                                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ doRegister(name) }, 2000)
                            } else {
                                android.widget.Toast.makeText(this@MainActivity, "HID Registration Failed (System Rejected)", android.widget.Toast.LENGTH_LONG).show()
                            }
                        }
                    }
                }

            override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
                Log.d("HID", "HID state changed: $state for ${device.name}")
                when (state) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        targetDevice = device
                        startHidService()
                        runOnUiThread {
                            eventSink?.success(mapOf(
                                "connection_state" to "connected",
                                "address" to device.address,
                                "name" to (device.name ?: "Unknown")
                            ))
                            android.widget.Toast.makeText(this@MainActivity, "✓ ${device.name} connected as keyboard!", android.widget.Toast.LENGTH_LONG).show()
                        }
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        targetDevice = null
                        stopHidService()
                        runOnUiThread {
                            eventSink?.success(mapOf("connection_state" to "disconnected"))
                        }
                    }
                }
            }
        })
    }

    private fun startClassicScan() {
        discoveredDevices.clear()
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter?.isDiscovering == true) bluetoothAdapter.cancelDiscovery()
        bluetoothAdapter?.startDiscovery()
        Log.d("BT", "Classic discovery started")
    }

    private fun stopClassicScan() {
        BluetoothAdapter.getDefaultAdapter()?.cancelDiscovery()
    }

    private fun connectHid(address: String) {
        try {
            val device = BluetoothAdapter.getDefaultAdapter().getRemoteDevice(address)
            Log.d("HID", "Connecting HID to ${device.name} ($address)")
            bluetoothHidDevice?.connect(device)
        } catch (e: Exception) {
            Log.e("HID", "Connect failed: ${e.message}")
        }
    }

    private fun setBluetoothName(name: String): Boolean {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        return if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
            bluetoothAdapter.setName(name)
        } else false
    }

    private fun unpairDevice(address: String): Boolean {
        return try {
            val device = BluetoothAdapter.getDefaultAdapter().getRemoteDevice(address)
            val method = device.javaClass.getMethod("removeBond")
            val success = method.invoke(device) as Boolean
            Log.d("BT", "Unpair device $address: $success")
            success
        } catch (e: Exception) {
            Log.e("BT", "Unpair failed: ${e.message}")
            false
        }
    }

    private fun disconnectHid() {
        if (bluetoothHidDevice != null && targetDevice != null) {
            Log.d("HID", "Explicitly disconnecting ${targetDevice?.name}")
            bluetoothHidDevice?.disconnect(targetDevice!!)
            targetDevice = null
        }
    }

    private fun setDiscoverable(duration: Int) {
        startHidService() // Keep alive during discovery too
        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
            putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, duration)
        }
        startActivity(intent)
    }

    private fun startHidService() {
        val serviceIntent = Intent(this, HidService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopHidService() {
        val serviceIntent = Intent(this, HidService::class.java)
        stopService(serviceIntent)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopHidService()
        unregisterReceiver(discoveryReceiver)
        stopClassicScan()
    }
}
