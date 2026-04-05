import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../app_state.dart';

class BleTerminalScreen extends StatelessWidget {
  const BleTerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Stack(
        children: [
          _buildBackgroundLayers(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(appState),
                _buildScannerControl(appState),
                Expanded(child: _buildDeviceList(appState)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundLayers() {
    return Stack(
      children: [
        Positioned(
          top: -100, right: -100,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withValues(alpha: 0.1),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .blur(begin: const Offset(40, 40), end: const Offset(80, 80), duration: 10.seconds),
        ),
      ],
    );
  }

  Widget _buildHeader(AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BLE TERMINAL",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0),
          ).animate().fadeIn().slideX(begin: -0.2),
          Text(
            "SECURE DEVICE DISCOVERY SYSTEM",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent.withValues(alpha: 0.7), letterSpacing: 1.5),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildScannerControl(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: _buildNeonContainer(
        color: Colors.blueAccent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SCANNER STATUS", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(appState.isScanning ? "ADVERTISING SCAN IN PROGRESS..." : "SCANNER STANDBY", 
                  style: TextStyle(color: appState.isScanning ? Colors.blueAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.w900)),
              ],
            ),
            const Spacer(),
            IconButton.filled(
              onPressed: appState.isScanning ? appState.stopScan : appState.startScan,
              icon: Icon(appState.isScanning ? Icons.stop_rounded : Icons.search_rounded),
              style: IconButton.styleFrom(
                backgroundColor: appState.isScanning ? Colors.redAccent.withValues(alpha: 0.2) : Colors.blueAccent.withValues(alpha: 0.2),
                foregroundColor: appState.isScanning ? Colors.redAccent : Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildDeviceList(AppState appState) {
    final results = appState.scanResults;
    
    if (results.isEmpty && !appState.isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_audio_rounded, size: 64, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
            const Text("NO DEVICES DETECTED", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        final name = r.advertisementData.localName.isNotEmpty ? r.advertisementData.localName : "UNKNOWN DEVICE";
        final isConnected = appState.connectedDevice?.remoteId == r.device.remoteId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDeviceItem(name, r, isConnected, appState),
        );
      },
    );
  }

  Widget _buildDeviceItem(String name, ScanResult r, bool isConnected, AppState appState) {
    return _buildNeonContainer(
      color: isConnected ? Colors.cyanAccent : Colors.white12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isConnected ? Colors.cyanAccent : Colors.blueAccent).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded, 
              color: isConnected ? Colors.cyanAccent : Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                Text(r.device.remoteId.str, style: const TextStyle(color: Colors.white38, fontSize: 9)),
              ],
            ),
          ),
          Text("${r.rssi} dBm", style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          TextButton(
            onPressed: isConnected ? appState.disconnectDevice : () => appState.connectToDevice(r.device),
            style: TextButton.styleFrom(
              backgroundColor: (isConnected ? Colors.redAccent : Colors.blueAccent).withValues(alpha: 0.1),
              foregroundColor: isConnected ? Colors.redAccent : Colors.cyanAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isConnected ? "HALT" : "LINK", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1);
  }

  Widget _buildNeonContainer({required Widget child, required Color color, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
