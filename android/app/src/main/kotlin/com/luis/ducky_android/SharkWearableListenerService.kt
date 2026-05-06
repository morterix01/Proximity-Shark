package com.luis.ducky_android

import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import java.nio.charset.StandardCharsets

class SharkWearableListenerService : WearableListenerService() {

    override fun onMessageReceived(messageEvent: MessageEvent) {
        val path = messageEvent.path
        val payload = String(messageEvent.data, StandardCharsets.UTF_8)
        Log.d("SharkWearListener", "Received message: $path")

        when (path) {
            "/connect_device" -> {
                ensureServiceStarted()
                HidManager.connect(payload)
            }
            "/panic" -> {
                ensureServiceStarted()
                // Send Ctrl+Alt+B (modifier 0x05, keycode 0x05)
                val pressed = byteArrayOf(0x05.toByte(), 0x00, 0x05.toByte(), 0x00, 0x00, 0x00, 0x00, 0x00)
                val released = byteArrayOf(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
                HidManager.sendReport(pressed)
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    HidManager.sendReport(released)
                }, 50)
            }
            "/taskkill" -> {
                // Taskkill and Shutdown scripts are complex DuckyScripts handled in Dart.
                // However, if the app is killed, we might need a native "fallback" or 
                // just rely on the watch sending a simpler command.
                // For now, we'll focus on connection stability which was the main complaint.
            }
        }
    }

    private fun ensureServiceStarted() {
        val intent = Intent(this, HidService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        // Ensure HidManager is initialized
        HidManager.initialize(this, "Proximity Shark")
    }
}
