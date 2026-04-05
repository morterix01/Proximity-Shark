import 'package:flutter/services.dart';

class HidController {
  static const MethodChannel _channel = MethodChannel('com.luis.ducky_android/hid');

  Future<bool> connect(String address) async {
    try {
      final bool success = await _channel.invokeMethod('connect', {'address': address});
      return success;
    } on PlatformException catch (e) {
      print("Failed to connect: ${e.message}");
      return false;
    }
  }

  Future<bool> sendReport(Uint8List report) async {
    try {
      final bool success = await _channel.invokeMethod('sendReport', {'report': report});
      return success;
    } on PlatformException catch (e) {
      print("Failed to send report: ${e.message}");
      return false;
    }
  }

  Future<int> getConnectionStatus() async {
    try {
      final int status = await _channel.invokeMethod('getConnectionStatus');
      return status;
    } on PlatformException catch (e) {
      print("Failed to get status: ${e.message}");
      return 0;
    }
  }

  /// Sends a key press and release (8-byte report)
  Future<void> sendKey(int modifier, int keycode) async {
    // Press
    Uint8List pressReport = Uint8List(8);
    pressReport[0] = modifier;
    pressReport[2] = keycode;
    await sendReport(pressReport);

    // Release
    Uint8List releaseReport = Uint8List(8);
    await sendReport(releaseReport);
  }

  /// Sets the local Bluetooth device name
  Future<bool> setDeviceName(String name) async {
    try {
      final bool success = await _channel.invokeMethod('setDeviceName', {'name': name});
      return success;
    } on PlatformException catch (e) {
      print("Failed to set name: ${e.message}");
      return false;
    }
  }

  /// Sets the device in discoverable mode
  Future<bool> setDiscoverable(int duration) async {
    try {
      final bool success = await _channel.invokeMethod('setDiscoverable', {'duration': duration});
      return success;
    } on PlatformException catch (e) {
      print("Failed to set discoverable: ${e.message}");
      return false;
    }
  }
}
