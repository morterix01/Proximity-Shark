package com.luis.ducky_android

import android.bluetooth.*
import android.bluetooth.le.*
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
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null
    private var targetDevice: BluetoothDevice? = null
    private var isHidRegistered = false
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
                        result.success(connectHid(address))
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
                "isHidReady" -> {
                    result.success(isHidRegistered)
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
        }
        registerReceiver(discoveryReceiver, filter)

        val adapter = BluetoothAdapter.getDefaultAdapter()
        adapter?.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                if (profile == BluetoothProfile.HID_DEVICE) {
                    bluetoothHidDevice = proxy as BluetoothHidDevice
                    pendingDeviceName?.let { doRegister(it) }
                }
            }
            override fun onServiceDisconnected(profile: Int) {
                if (profile == BluetoothProfile.HID_DEVICE) {
                    bluetoothHidDevice = null
                }
            }
        }, BluetoothProfile.HID_DEVICE)
        
        bluetoothLeAdvertiser = adapter?.bluetoothLeAdvertiser
    }

    private var retryCount = 0

    private fun initHidProfile(deviceName: String) {
        setBluetoothName(deviceName)
        pendingDeviceName = deviceName
        spoofDeviceClass() // Attempt to mask as keyboard

        if (bluetoothHidDevice != null) {
            doRegister(deviceName)
        }
    }

    private fun doRegister(name: String) {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter == null || !adapter.isEnabled) return

        if (bluetoothHidDevice == null) return

        try {
            bluetoothHidDevice?.unregisterApp()
        } catch (e: Exception) {
            Log.w("HID", "Unregister failed: ${e.message}")
        }

        // Refined SDP settings for professional keyboard appearance
        val sdp = BluetoothHidDeviceAppSdpSettings(
            "HID Keyboard",
            "Professional HID Input Device",
            "Shark Technologies",
            BluetoothHidDevice.SUBCLASS1_KEYBOARD,
            HID_DESCRIPTOR
        )

        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            bluetoothHidDevice?.registerApp(sdp, null, null, { it.run() }, object : BluetoothHidDevice.Callback() {
                override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
                    isHidRegistered = registered
                    runOnUiThread {
                        eventSink?.success(mapOf("hid_status" to registered))
                        if (registered) {
                            retryCount = 0
                        } else if (retryCount < 1) {
                            retryCount++
                            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ doRegister(name) }, 2000)
                        }
                    }
                }

                override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
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
        }, 1500)
    }

    private fun spoofDeviceClass() {
        try {
            val adapter = BluetoothAdapter.getDefaultAdapter() ?: return
            // 0x0540 is the class for a Peripheral/Keyboard
            val setDeviceClass = adapter.javaClass.getMethod("setDeviceClass", Int::class.java)
            val result = setDeviceClass.invoke(adapter, 0x0540) as Boolean
            Log.d("IDENTITY", "Spoof CoD (0x0540) result: $result")
        } catch (e: Exception) {
            Log.w("IDENTITY", "Could not spoof CoD via reflection: ${e.message}")
        }
    }

    private var advertiseCallback: AdvertiseCallback? = null

    private fun startBleAdvertising() {
        if (bluetoothLeAdvertiser == null) return
        stopBleAdvertising()

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .addServiceUuid(android.os.ParcelUuid.fromString("00001124-0000-1000-8000-00805f9b34fb")) // HID Service UUID
            .build()
        
        // This is the CRITICAL part for Windows: including the Keyboard Appearance (0x03C1)
        val scanResponse = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                Log.d("IDENTITY", "BLE Masking Active (Appearance logic handled by system stack)")
            }
        }

        try {
            bluetoothLeAdvertiser?.startAdvertising(settings, data, scanResponse, advertiseCallback)
        } catch (e: Exception) {
            Log.e("IDENTITY", "BLE Advertising failed: ${e.message}")
        }
    }

    private fun stopBleAdvertising() {
        advertiseCallback?.let {
            bluetoothLeAdvertiser?.stopAdvertising(it)
            advertiseCallback = null
        }
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

    private fun connectHid(address: String): Boolean {
        return try {
            val adapter = BluetoothAdapter.getDefaultAdapter()
            val device = adapter.getRemoteDevice(address)
            
            if (bluetoothHidDevice == null || !isHidRegistered) return false
            
            val currentState = bluetoothHidDevice!!.getConnectionState(device)
            if (currentState != BluetoothProfile.STATE_DISCONNECTED) {
                bluetoothHidDevice!!.disconnect(device)
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    bluetoothHidDevice!!.connect(device)
                }, 800)
                return true
            }
            
            bluetoothHidDevice!!.connect(device)
        } catch (e: Exception) {
            false
        }
    }

    private fun setBluetoothName(name: String): Boolean {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        return if (adapter != null && adapter.isEnabled) {
            adapter.setName(name)
        } else false
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

    private fun disconnectHid() {
        if (bluetoothHidDevice != null && targetDevice != null) {
            bluetoothHidDevice?.disconnect(targetDevice!!)
            targetDevice = null
        }
    }

    private fun setDiscoverable(duration: Int) {
        startHidService()
        startBleAdvertising() // Start BLE mask alongside classic visibility
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
        stopBleAdvertising()
        stopHidService()
        try {
            unregisterReceiver(discoveryReceiver)
        } catch (e: Exception) {}
        stopClassicScan()
    }
}
