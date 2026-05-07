package com.luis.ducky_android

import android.bluetooth.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import com.google.android.gms.wearable.DataMap
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class MainActivity : FlutterActivity() {
    private val CHANNEL       = "com.luis.ducky_android/hid"
    private val CHAT_CHANNEL  = "com.luis.ducky_android/chat"
    private val EVENT_CHANNEL = "com.luis.ducky_android/devices"
    private val discoveredDevices = mutableListOf<Map<String, String>>()
    private var eventSink: EventChannel.EventSink? = null
    private var chatMethodChannel: MethodChannel? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

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

        // ── HID channel ──────────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startClassicScan" -> { startClassicScan(); result.success(true) }
                "stopClassicScan"  -> { stopClassicScan();  result.success(true) }
                "connectHid" -> {
                    val address = call.argument<String>("address")
                    if (address != null) result.success(HidManager.connect(address))
                    else result.error("INVALID_ADDRESS", "Address is null", null)
                }
                "getBondedDevices" -> {
                    val bonded = BluetoothAdapter.getDefaultAdapter()?.bondedDevices?.map {
                        mapOf("name" to (it.name ?: "Unknown"), "address" to it.address)
                    } ?: emptyList<Map<String,String>>()
                    result.success(bonded)
                }
                "sendReport" -> {
                    val report = call.argument<ByteArray>("report")
                    if (report != null) result.success(HidManager.sendReport(report))
                    else result.error("SEND_FAILED", "Null report", null)
                }
                "getConnectionStatus" -> result.success(HidManager.getStatus())
                "setDiscoverable" -> {
                    setDiscoverable(call.argument<Int>("duration") ?: 300)
                    result.success(true)
                }
                "unpairDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null) result.success(unpairDevice(address))
                    else result.error("INVALID_ADDRESS", "Address is null", null)
                }
                "disconnectHid" -> { HidManager.disconnect(); result.success(true) }
                "initHidProfile" -> {
                    val name = call.argument<String>("deviceName") ?: "Proximity Shark"
                    // Update the Bluetooth adapter name so Windows/PC sees the correct identity
                    HidManager.setAdapterName(name)
                    HidManager.initialize(this, name)
                    result.success(true)
                }
                // Used by SharkChatScreen to display a user-friendly device name
                "getDeviceName" -> {
                    val name = try { android.os.Build.MODEL } catch (e: Exception) { "Shark" }
                    result.success(name)
                }
                "setAdapterName" -> {
                    val name = call.argument<String>("name") ?: return@setMethodCallHandler
                    HidManager.setAdapterName(name)
                    result.success(true)
                }
                "isBluetoothEnabled" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    result.success(adapter?.isEnabled == true)
                }
                else -> result.notImplemented()
            }
        }

        // ── Chat channel (Flutter ↔ WearOS DataClient) ───────────────────────────
        val chatCh = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHAT_CHANNEL)
        chatMethodChannel = chatCh
        chatCh.setMethodCallHandler { call, result ->
            when (call.method) {
                // Called by Dart whenever the chat state changes → push to watch
                "syncChatToWatch" -> {
                    val jsonStr = call.argument<String>("json") ?: ""
                    scope.launch(Dispatchers.IO) {
                        try {
                            val request = PutDataMapRequest.create("/chat_state").apply {
                                dataMap.putString("chat_json", jsonStr)
                                dataMap.putLong("ts", System.currentTimeMillis())
                            }
                            Wearable.getDataClient(this@MainActivity)
                                .putDataItem(request.asPutDataRequest().setUrgent())
                                .await()
                            Log.d("SharkChat", "Chat state pushed to watch")
                        } catch (e: Exception) {
                            Log.w("SharkChat", "syncChatToWatch failed: ${e.message}")
                        }
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── BroadcastReceiver: chat messages forwarded from SharkWearableListenerService ──
    private val chatFromWatchReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != SharkWearableListenerService.ACTION_CHAT_SEND) return
            val text = intent.getStringExtra(SharkWearableListenerService.EXTRA_CHAT_TEXT) ?: return
            Log.d("SharkChat", "Forwarding watch chat to Flutter: $text")
            runOnUiThread {
                chatMethodChannel?.invokeMethod("chatSendFromWatch", text)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Register BT receiver
        val btFilter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
        }
        registerReceiver(bluetoothReceiver, btFilter)

        // Register chat-from-watch receiver
        val chatFilter = IntentFilter(SharkWearableListenerService.ACTION_CHAT_SEND)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(chatFromWatchReceiver, chatFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(chatFromWatchReceiver, chatFilter)
        }

        // HID setup — load user-defined name from SharedPreferences
        val savedName = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.ble_name", null)
            ?: "Proximity Shark"
        Log.d("MainActivity", "Initializing HID with name: $savedName")
        HidManager.setAdapterName(savedName)
        HidManager.initialize(this, savedName)
        HidManager.setStateCallback { device, state ->
            val status = if (state == BluetoothProfile.STATE_CONNECTED) "connected" else "disconnected"
            val entry = mutableMapOf<String, String>("connection_state" to status)
            device?.let {
                entry["address"] = it.address
                entry["name"]    = it.name ?: "Unknown"
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
        try { unregisterReceiver(chatFromWatchReceiver) } catch (e: Exception) { /* already unregistered */ }
        scope.cancel()
    }
}
