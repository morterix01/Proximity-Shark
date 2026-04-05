import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _nameController.text = appState.bleName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Stack(
        children: [
          _buildBackground(),
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
                  _buildIdentityConfig(context, appState),
                  const SizedBox(height: 24),
                  _buildQuickAction(context, appState),
                  const SizedBox(height: 24),
                  _buildStatsGrid(appState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background ───────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Positioned(
      top: -60, right: -60,
      child: Container(
        width: 320, height: 320,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.cyanAccent.withValues(alpha: 0.04),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .blur(begin: const Offset(40, 40), end: const Offset(80, 80), duration: 10.seconds),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PROXIMITY SHARK",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3.0),
        ).animate().fadeIn().slideX(begin: -0.2),
        Text(
          "HYPER-MOBILE HID INJECTION UNIT // REV 4.0",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent.withValues(alpha: 0.7), letterSpacing: 1.5),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  // ─── Status Card ──────────────────────────────────────────────────────────
  Widget _buildStatusCard(AppState appState) {
    final isConnected = appState.connectionStatus == 1;
    final color = isConnected ? Colors.greenAccent : Colors.redAccent;

    return _neonBox(
      color: color,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _statusDot(isConnected, color),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SYSTEM STATUS",
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text(
                  isConnected ? "CONNECTED — HID KEYBOARD ACTIVE" : "AWAITING TARGET CONNECTION...",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                ),
                if (isConnected && appState.connectedAddress != null)
                  Text(
                    "ADDR: ${appState.connectedAddress!.toUpperCase()}",
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _statusDot(bool isConnected, Color color) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(
        child: Icon(
          isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
          color: color, size: 24,
        ),
      ),
    ).animate(onPlay: (c) => isConnected ? c.repeat(reverse: true) : c.stop())
     .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds);
  }

  // ─── Identity Config ──────────────────────────────────────────────────────
  Widget _buildIdentityConfig(BuildContext context, AppState appState) {
    return _neonBox(
      color: Colors.white24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DEVICE IDENTITY",
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          // Name field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "Device name shown to PC...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (val) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    appState.updateBleName(val);
                  },
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (_nameController.text != appState.bleName) {
                      appState.updateBleName(_nameController.text);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () => appState.updateBleName(_nameController.text),
                icon: const Icon(Icons.check_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
                  foregroundColor: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Visibility section with step guide
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("VISIBILITY", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("1. Press GO VISIBLE", style: TextStyle(color: Colors.white38, fontSize: 9)),
                    Text("2. Accept the system dialog", style: TextStyle(color: Colors.white38, fontSize: 9)),
                    Text("3. Search Bluetooth on your PC", style: TextStyle(color: Colors.white38, fontSize: 9)),
                    Text("4. Select 'Proximity Shark' on PC", style: TextStyle(color: Colors.white38, fontSize: 9)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_nameController.text != appState.bleName && _nameController.text.isNotEmpty) {
                    await appState.updateBleName(_nameController.text);
                  }
                  appState.toggleDiscoverability();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Accept the system dialog → then search Bluetooth on your PC"),
                        backgroundColor: Color(0xFF1A1A2E),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.wifi_tethering_rounded, size: 16),
                label: const Text("GO VISIBLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2);
  }

  // ─── Quick Action ─────────────────────────────────────────────────────────
  Widget _buildQuickAction(BuildContext context, AppState appState) {
    return InkWell(
      onTap: appState.isExecuting
          ? null
          : () {
              if (appState.connectionStatus == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No target connected — pair your PC first via HID Terminal")),
                );
                return;
              }
              appState.runScript();
            },
      borderRadius: BorderRadius.circular(24),
      child: _neonBox(
        color: Colors.cyanAccent,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              appState.isExecuting ? Icons.hourglass_top_rounded : Icons.bolt_rounded,
              color: Colors.cyanAccent, size: 32,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("QUICK ACTION",
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  Text(
                    appState.isExecuting ? "EXECUTING PAYLOAD..." : "LAUNCH ACTIVE PAYLOAD",
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (appState.isExecuting)
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
              )
            else
              Icon(Icons.play_arrow_rounded, color: Colors.cyanAccent.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  // ─── Stats Grid ───────────────────────────────────────────────────────────
  Widget _buildStatsGrid(AppState appState) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _statTile("STORED SCRIPTS", "${appState.savedScripts.length}", Icons.folder_rounded, Colors.amberAccent),
        _statTile("TOTAL DEPLOYS", "${appState.executionCount}", Icons.rocket_launch_rounded, Colors.purpleAccent),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return _neonBox(
      color: Colors.white12,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  // ─── Shared Widget ────────────────────────────────────────────────────────
  Widget _neonBox({required Widget child, required Color color, EdgeInsets? padding}) {
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
