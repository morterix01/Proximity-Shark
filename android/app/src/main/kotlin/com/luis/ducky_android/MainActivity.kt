package com.luis.ducky_android

import android.bluetooth.*
import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.luis.ducky_android/hid"
    private var bluetoothHidDevice: BluetoothHidDevice? = null
    private var targetDevice: BluetoothDevice? = null

    // Standard HID Keyboard Descriptor
    private val HID_DESCRIPTOR = byteArrayOf(
        0x05.toByte(), 0x01.toByte(),        // Usage Page (Generic Desktop)
        0x09.toByte(), 0x06.toByte(),        // Usage (Keyboard)
        0xA1.toByte(), 0x01.toByte(),        // Collection (Application)
        0x05.toByte(), 0x07.toByte(),        // Usage Page (Key Codes)
        0x19.toByte(), 0xE0.toByte(),        // Usage Minimum (224)
        0x29.toByte(), 0xE7.toByte(),        // Usage Maximum (231)
        0x15.toByte(), 0x00.toByte(),        // Logical Minimum (0)
        0x25.toByte(), 0x01.toByte(),        // Logical Maximum (1)
        0x75.toByte(), 0x01.toByte(),        // Report Size (1)
        0x95.toByte(), 0x08.toByte(),        // Report Count (8)
        0x81.toByte(), 0x02.toByte(),        // Input (Data, Variable, Absolute) ; Modifier byte
        0x95.toByte(), 0x01.toByte(),        // Report Count (1)
        0x75.toByte(), 0x08.toByte(),        // Report Size (8)
        0x81.toByte(), 0x01.toByte(),        // Input (Constant) ; Reserved byte
        0x95.toByte(), 0x05.toByte(),        // Report Count (5)
        0x75.toByte(), 0x01.toByte(),        // Report Size (1)
        0x05.toByte(), 0x08.toByte(),        // Usage Page (LEDs)
        0x19.toByte(), 0x01.toByte(),        // Usage Minimum (1)
        0x29.toByte(), 0x05.toByte(),        // Usage Maximum (5)
        0x91.toByte(), 0x02.toByte(),        // Output (Data, Variable, Absolute) ; LED report
        0x95.toByte(), 0x01.toByte(),        // Report Count (1)
        0x75.toByte(), 0x03.toByte(),        // Report Size (3)
        0x91.toByte(), 0x01.toByte(),        // Output (Constant) ; LED report padding
        0x95.toByte(), 0x06.toByte(),        // Report Count (6)
        0x75.toByte(), 0x08.toByte(),        // Report Size (8)
        0x15.toByte(), 0x00.toByte(),        // Logical Minimum (0)
        0x25.toByte(), 0x65.toByte(),        // Logical Maximum (101)
        0x05.toByte(), 0x07.toByte(),        // Usage Page (Key Codes)
        0x19.toByte(), 0x00.toByte(),        // Usage Minimum (0)
        0x29.toByte(), 0x65.toByte(),        // Usage Maximum (101)
        0x81.toByte(), 0x00.toByte(),        // Input (Data, Array) ; Key codes
        0xC0.toByte()                        // End Collection
    )

    private val sdpSettings = BluetoothHidDeviceAppSdpSettings(
        "DuckyAndroid",
        "Android HID Keyboard",
        "Luis",
        BluetoothHidDevice.SUBCLASS1_KEYBOARD,
        HID_DESCRIPTOR
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "connect" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        connectToDevice(address)
                        result.success(true)
                    } else {
                        result.error("INVALID_ADDRESS", "Address is null", null)
                    }
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
                        val success = setBluetoothName(name)
                        result.success(success)
                    } else {
                        result.error("INVALID_NAME", "Name is null", null)
                    }
                }
                "setDiscoverable" -> {
                    val duration = call.argument<Int>("duration") ?: 300
                    setDiscoverable(duration)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        bluetoothAdapter?.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                if (profile == BluetoothProfile.HID_DEVICE) {
                    bluetoothHidDevice = proxy as BluetoothHidDevice
                    registerApp()
                }
            }

            override fun onServiceDisconnected(profile: Int) {
                if (profile == BluetoothProfile.HID_DEVICE) {
                    bluetoothHidDevice = null
                }
            }
        }, BluetoothProfile.HID_DEVICE)
    }

    private fun registerApp() {
        bluetoothHidDevice?.registerApp(sdpSettings, null, null, { it.run() }, object : BluetoothHidDevice.Callback() {
            override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
                Log.d("HID", "App registered: $registered")
                runOnUiThread {
                    if (registered) {
                        android.widget.Toast.makeText(this@MainActivity, "HID Profile Ready", android.widget.Toast.LENGTH_SHORT).show()
                    } else {
                        android.widget.Toast.makeText(this@MainActivity, "HID Registration Failed!", android.widget.Toast.LENGTH_LONG).show()
                    }
                }
            }

            override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
                Log.d("HID", "Connection state: $state")
                if (state == BluetoothProfile.STATE_CONNECTED) {
                    targetDevice = device
                    runOnUiThread {
                        android.widget.Toast.makeText(this@MainActivity, "PC Connected", android.widget.Toast.LENGTH_SHORT).show()
                    }
                } else if (state == BluetoothProfile.STATE_DISCONNECTED) {
                    targetDevice = null
                }
            }
        })
    }

    private fun connectToDevice(address: String) {
        val device = BluetoothAdapter.getDefaultAdapter().getRemoteDevice(address)
        bluetoothHidDevice?.connect(device)
    }

    private fun setBluetoothName(name: String): Boolean {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
            return bluetoothAdapter.setName(name)
        }
        return false
    }

    private fun setDiscoverable(duration: Int) {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter != null) {
            val intent = android.content.Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
                putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, duration)
            }
            startActivity(intent)
        }
    }
}
