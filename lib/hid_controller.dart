import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class HidController {
  static const _channel = MethodChannel('com.luis.ducky_android/hid');
  static const _eventChannel = EventChannel('com.luis.ducky_android/devices');

  /// Stream of discovered Classic Bluetooth devices
  Stream<Map<dynamic, dynamic>> get deviceStream =>
      _eventChannel.receiveBroadcastStream().cast<Map<dynamic, dynamic>>();

  /// Start Classic Bluetooth (non-BLE) device discovery
  Future<void> startClassicScan() async {
    try {
      await _channel.invokeMethod('startClassicScan');
    } on PlatformException catch (e) {
      debugPrint("Failed to start scan: ${e.message}");
    }
  }

  /// Stop Classic Bluetooth discovery
  Future<void> stopClassicScan() async {
    try {
      await _channel.invokeMethod('stopClassicScan');
    } on PlatformException catch (e) {
      debugPrint("Failed to stop scan: ${e.message}");
    }
  }

  /// Connect to a device as HID keyboard using its Classic BT address
  Future<bool> connectHid(String address) async {
    try {
      final bool success = await _channel.invokeMethod('connectHid', {'address': address});
      return success;
    } on PlatformException catch (e) {
      debugPrint("Failed to connect HID: ${e.message}");
      return false;
    }
  }

  /// Returns all bonded (paired) Bluetooth devices from Android system
  Future<List<Map<dynamic, dynamic>>> getBondedDevices() async {
    try {
      final List result = await _channel.invokeMethod('getBondedDevices');
      return result.cast<Map<dynamic, dynamic>>();
    } on PlatformException catch (e) {
      debugPrint("Failed to get bonded devices: ${e.message}");
      return [];
    }
  }

  /// Unpairs (unbonds) a device from physical system Bluetooth list
  Future<bool> unpairDevice(String address) async {
    try {
      final bool success = await _channel.invokeMethod('unpairDevice', {'address': address});
      return success;
    } on PlatformException catch (e) {
      debugPrint("Failed to unpair device: ${e.message}");
      return false;
    }
  }

  /// Disconnects the current HID session
  Future<void> disconnectHid() async {
    try {
      await _channel.invokeMethod('disconnectHid');
    } on PlatformException catch (e) {
      debugPrint("Failed to disconnect HID: ${e.message}");
    }
  }

  /// Sends a raw HID keyboard report to the connected device
  Future<bool> sendReport(List<int> report) async {
    try {
      final bool success = await _channel.invokeMethod('sendReport',
          {'report': Uint8List.fromList(report)});
      return success;
    } on PlatformException catch (e) {
      debugPrint("Failed to send report: ${e.message}");
      return false;
    }
  }

  /// Sends a single key press (modifier + keycode) as a complete HID report
  Future<bool> sendKey(int modifier, int keycode) async {
    // HID report: [modifier, reserved, key1, key2, key3, key4, key5, key6]
    final pressed = [modifier, 0x00, keycode, 0x00, 0x00, 0x00, 0x00, 0x00];
    final released = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
    final ok = await sendReport(pressed);
    await Future.delayed(const Duration(milliseconds: 5));
    await sendReport(released);
    return ok;
  }

  /// Returns 1 if a PC is connected, 0 otherwise
  Future<int> getConnectionStatus() async {
    try {
      final int status = await _channel.invokeMethod('getConnectionStatus');
      return status;
    } on PlatformException catch (e) {
      debugPrint("Failed to get status: ${e.message}");
      return 0;
    }
  }

  /// Sets the local Bluetooth device name and initializes the HID Profile with that name
  Future<bool> initHidProfile(String name) async {
    try {
      final bool success = await _channel.invokeMethod('initHidProfile', {'deviceName': name});
      return success;
    } on PlatformException catch (e) {
      debugPrint("Failed to init HID profile: ${e.message}");
      return false;
    }
  }

  /// Sets the device in discoverable mode (Android system popup)
  Future<bool> setDiscoverable(int duration) async {
    try {
      final bool success = await _channel.invokeMethod('setDiscoverable', {'duration': duration});
      return success;
    } on PlatformException catch (e) {
      debugPrint("Failed to set discoverable: ${e.message}");
      return false;
    }
  }
}
