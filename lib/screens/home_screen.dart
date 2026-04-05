import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Stack(
        children: [
          _buildBackgroundLayers(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(appState),
                  const SizedBox(height: 32),
                  _buildStatusCard(appState),
                  const SizedBox(height: 24),
                  _buildQuickActionCard(context, appState),
                  const SizedBox(height: 24),
                  _buildSystemInfoGrid(appState),
                ],
              ),
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
          top: -50, right: -50,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyanAccent.withValues(alpha: 0.05),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .blur(begin: const Offset(40, 40), end: const Offset(80, 80), duration: 10.seconds),
        ),
      ],
    );
  }

  Widget _buildHeader(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PROXIMITY SHARK",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3.0),
        ).animate().fadeIn().slideX(begin: -0.2),
        Text(
          "HYPER-MOBILE HID INJECTION UNIT // REV 3.0",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent.withValues(alpha: 0.7), letterSpacing: 1.5),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildStatusCard(AppState appState) {
    final isConnected = appState.connectionStatus == 1;
    final color = isConnected ? Colors.greenAccent : Colors.redAccent;

    return _buildNeonContainer(
      color: color,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _buildStatusIndicator(isConnected, color),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SYSTEM STATUS", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text(isConnected ? "CONNECTED TO PERIPHERAL" : "WAITING FOR CONNECTION...", 
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                if (isConnected && appState.connectedDevice != null)
                  Text("ID: ${appState.connectedDevice!.remoteId.str.toUpperCase()}", style: TextStyle(color: Colors.white38, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildStatusIndicator(bool isConnected, Color color) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(
        child: Icon(isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded, color: color, size: 24),
      ),
    ).animate(onPlay: (c) => isConnected ? c.repeat(reverse: true) : c.stop()).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds);
  }

  Widget _buildQuickActionCard(BuildContext context, AppState appState) {
    return InkWell(
      onTap: () => appState.currentNavIndex = 2, // Go to Editor
      child: _buildNeonContainer(
        color: Colors.cyanAccent,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.cyanAccent, size: 32),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("QUICK START", style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  Text("LAUNCH ACTIVE PAYLOAD", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.cyanAccent.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildSystemInfoGrid(AppState appState) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildInfoTile("STORED SCRIPTS", "${appState.savedScripts.length}", Icons.folder_rounded, Colors.amberAccent),
        _buildInfoTile("ENGINE UPTIME", "99.9%", Icons.speed_rounded, Colors.blueAccent),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return _buildNeonContainer(
      color: Colors.white12,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNeonContainer({required Widget child, required Color color, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
