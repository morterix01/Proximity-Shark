import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                _buildHeader(),
                _buildInfoBanner(),
                if (appState.lastDevice != null)
                  _buildQuickReconnect(context, appState),
                _buildScannerControl(appState),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                  child: Text("DISCOVERED DEVICES", style: TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                ),
                Expanded(child: _buildDeviceList(context, appState)),
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
              color: Colors.blueAccent.withValues(alpha: 0.08),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .blur(begin: const Offset(40, 40), end: const Offset(80, 80), duration: 10.seconds),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "HID TERMINAL",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0),
          ).animate().fadeIn().slideX(begin: -0.2),
          Text(
            "CLASSIC BLUETOOTH DEVICE SCANNER",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent.withValues(alpha: 0.7), letterSpacing: 1.5),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 16),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Scansione Bluetooth Classic. Clicca LINK, poi accetta l'abbinamento sul PC. Una volta connesso, usa QUICK ACTION per inviare script.",
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildQuickReconnect(BuildContext context, AppState appState) {
    final device = appState.lastDevice!;
    final isConnected = appState.connectionStatus == 1;
    final isConnecting = appState.connectingAddress == device.address;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: _buildNeonContainer(
        color: isConnected ? Colors.greenAccent : Colors.cyanAccent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isConnected ? Colors.greenAccent : Colors.cyanAccent).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isConnected ? Icons.link_rounded : Icons.link_off_rounded,
                color: isConnected ? Colors.greenAccent : Colors.cyanAccent, size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? "CONNECTED" : "LAST DEVICE",
                    style: TextStyle(
                      color: isConnected ? Colors.greenAccent : Colors.white38,
                      fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    device.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  Text(device.address, style: const TextStyle(color: Colors.white24, fontSize: 9)),
                ],
              ),
            ),
            if (isConnected)
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24)
            else if (isConnecting)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.amberAccent)),
                    SizedBox(width: 6),
                    Text("LINKING", style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: appState.isConnecting ? null : () {
                  appState.connectToDevice(device);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Reconnecting to ${device.name}..."),
                      backgroundColor: const Color(0xFF1A1A2E),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
                  foregroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Colors.cyanAccent, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on_rounded, size: 14),
                    SizedBox(width: 4),
                    Text("RECONNECT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
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
                Text(
                  appState.isScanning ? "SCANNING FOR DEVICES..." : "SCANNER STANDBY",
                  style: TextStyle(
                    color: appState.isScanning ? Colors.blueAccent : Colors.white70,
                    fontSize: 12, fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (appState.isScanning)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
              ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: appState.isScanning ? appState.stopScan : appState.startScan,
              icon: Icon(appState.isScanning ? Icons.stop_rounded : Icons.search_rounded),
              style: IconButton.styleFrom(
                backgroundColor: appState.isScanning
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : Colors.blueAccent.withValues(alpha: 0.2),
                foregroundColor: appState.isScanning ? Colors.redAccent : Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildDeviceList(BuildContext context, AppState appState) {
    final devices = appState.classicDevices;

    if (devices.isEmpty && !appState.isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_audio_rounded, size: 64, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
            const Text("NO DEVICES FOUND", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text("Press the search button to scan", style: TextStyle(color: Colors.white12, fontSize: 10)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final isConnected = appState.connectedAddress == device.address;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDeviceItem(context, device, isConnected, appState),
        );
      },
    );
  }

  Widget _buildDeviceItem(BuildContext context, ClassicDevice device, bool isConnected, AppState appState) {
    final color = isConnected ? Colors.greenAccent : Colors.blueAccent;
    return _buildNeonContainer(
      color: isConnected ? Colors.greenAccent : Colors.white12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isConnected ? Icons.bluetooth_connected_rounded : Icons.computer_rounded,
              color: color, size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(device.address, style: const TextStyle(color: Colors.white38, fontSize: 9)),
              ],
            ),
          ),
          Text("${device.rssi} dBm", style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Builder(builder: (context) {
            // Show LINKING only for the specific device being connected
            final isThisConnecting = appState.connectingAddress == device.address;
            if (isConnected) {
              return TextButton(
                onPressed: () => appState.disconnectDevice(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("HALT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              );
            } else if (isThisConnecting) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.amberAccent)),
                    SizedBox(width: 8),
                    Text("LINKING", style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              );
            } else {
              return TextButton(
                onPressed: appState.isConnecting ? null : () {
                  appState.connectToDevice(device);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Connecting to ${device.name}... Accept the pairing on your PC."),
                      backgroundColor: const Color(0xFF1A1A2E),
                      duration: const Duration(seconds: 6),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
                  foregroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("LINK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              );
            }
          }),
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
