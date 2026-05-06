package com.luis.ducky_android

import android.bluetooth.*
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log

object HidManager {
    private var bluetoothHidDevice: BluetoothHidDevice? = null
    private var targetDevice: BluetoothDevice? = null
    private var hidRegistered = false
    private var pendingConnectAddress: String? = null
    private var pendingDeviceName: String? = null
    private var isProxyBinding = false
    private var onStateChanged: ((BluetoothDevice?, Int) -> Unit)? = null

    fun setStateCallback(callback: (BluetoothDevice?, Int) -> Unit) {
        onStateChanged = callback
    }

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

    fun initialize(context: Context, deviceName: String?) {
        if (isProxyBinding || bluetoothHidDevice != null) return
        isProxyBinding = true
        pendingDeviceName = deviceName

        val adapter = BluetoothAdapter.getDefaultAdapter()
        adapter?.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                if (profile == BluetoothProfile.HID_DEVICE) {
                    bluetoothHidDevice = proxy as BluetoothHidDevice
                    isProxyBinding = false
                    Log.d("HidManager", "HID Profile proxy connected.")
                    pendingDeviceName?.let { doRegister(it) }
                }
            }
            override fun onServiceDisconnected(profile: Int) {
                if (profile == BluetoothProfile.HID_DEVICE) {
                    bluetoothHidDevice = null
                    isProxyBinding = false
                }
            }
        }, BluetoothProfile.HID_DEVICE)
    }

    private fun doRegister(name: String) {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter == null || !adapter.isEnabled || bluetoothHidDevice == null) return
        if (hidRegistered) return

        try {
            bluetoothHidDevice?.unregisterApp()
        } catch (e: Exception) {}

        val sdp = BluetoothHidDeviceAppSdpSettings(
            name, "Android HID Keyboard", name,
            BluetoothHidDevice.SUBCLASS1_KEYBOARD, HID_DESCRIPTOR
        )

        Handler(Looper.getMainLooper()).postDelayed({
            bluetoothHidDevice?.registerApp(sdp, null, null, { it.run() }, object : BluetoothHidDevice.Callback() {
                override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
                    hidRegistered = registered
                    Log.d("HidManager", "HID Registration: $registered")
                    if (registered && pendingConnectAddress != null) {
                        val addr = pendingConnectAddress!!
                        pendingConnectAddress = null
                        Handler(Looper.getMainLooper()).postDelayed({ doConnect(addr) }, 800)
                    }
                }

                override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
                    when (state) {
                        BluetoothProfile.STATE_CONNECTED -> targetDevice = device
                        BluetoothProfile.STATE_DISCONNECTED -> targetDevice = null
                    }
                    onStateChanged?.invoke(device, state)
                }
            })
        }, 1500)
    }

    fun connect(address: String): Boolean {
        if (bluetoothHidDevice == null || !hidRegistered) {
            pendingConnectAddress = address
            pendingDeviceName?.let { doRegister(it) }
            return true
        }
        doConnect(address)
        return true
    }

    private fun doConnect(address: String) {
        try {
            val device = BluetoothAdapter.getDefaultAdapter().getRemoteDevice(address)
            bluetoothHidDevice?.connect(device)
        } catch (e: Exception) {
            Log.e("HidManager", "doConnect failed: ${e.message}")
        }
    }

    fun sendReport(report: ByteArray): Boolean {
        return bluetoothHidDevice?.sendReport(targetDevice ?: return false, 1, report) ?: false
    }

    fun disconnect() {
        if (targetDevice != null) {
            bluetoothHidDevice?.disconnect(targetDevice!!)
            targetDevice = null
        }
    }

    fun getStatus(): Int = if (targetDevice != null) 1 else 0
}
