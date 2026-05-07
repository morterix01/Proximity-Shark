package com.luis.ducky_android

import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import java.nio.charset.StandardCharsets

class SharkWearableListenerService : WearableListenerService() {

    companion object {
        /** Action broadcast locally so MainActivity can forward to Flutter/SharkChatManager. */
        const val ACTION_CHAT_SEND = "com.luis.ducky_android.CHAT_SEND_FROM_WATCH"
        const val EXTRA_CHAT_TEXT  = "chat_text"
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        val path    = messageEvent.path
        val payload = String(messageEvent.data, StandardCharsets.UTF_8)
        Log.d("SharkWearListener", "Received message: $path")

        when (path) {
            "/connect_device" -> {
                ensureServiceStarted()
                HidManager.connect(payload)
            }
            "/panic" -> {
                ensureServiceStarted()
                val pressed  = byteArrayOf(0x05.toByte(), 0x00, 0x05.toByte(), 0x00, 0x00, 0x00, 0x00, 0x00)
                val released = byteArrayOf(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
                HidManager.sendReport(pressed)
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    HidManager.sendReport(released)
                }, 50)
            }
            "/taskkill" -> { /* handled via DuckyScript in Dart */ }

            // ── Shark Chat: watch → phone → Nearby peers ──────────────────────
            "/chat_send" -> {
                if (payload.isNotBlank()) {
                    Log.d("SharkWearListener", "Chat from watch: $payload")
                    // Broadcast locally so MainActivity can forward it to Flutter
                    val bcast = Intent(ACTION_CHAT_SEND).apply {
                        putExtra(EXTRA_CHAT_TEXT, payload)
                        setPackage(packageName) // explicit package → not exported
                    }
                    sendBroadcast(bcast)
                }
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
        HidManager.initialize(this, "Proximity Shark")
    }
}
