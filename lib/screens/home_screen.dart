import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_state.dart';
import '../enums.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _nameController.text = appState.bleName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (!_nameFocus.hasFocus && _nameController.text != appState.bleName) {
      _nameController.text = appState.bleName;
    }

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
                  _buildStealthHub(appState),
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
          "HYPER-MOBILE HID INJECTION UNIT // v1.0.4 // HYBRID KEYBOARD PC/ANDROID",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent.withValues(alpha: 0.7), letterSpacing: 1.5),
        ).animate().fadeIn(delay: 200.ms).shimmer(duration: 2.seconds, color: Colors.cyanAccent.withValues(alpha: 0.2)),
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
          _buildKeyboardLayoutSelector(appState),
          const SizedBox(height: 16),
          const Text("DEVICE IDENTITY",
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          // Name field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
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

  // ─── Stealth & Privacy Hub ────────────────────────────────────────────────
  Widget _buildStealthHub(AppState appState) {
    final isDanger = appState.isNetworkActive;
    final networkColor = isDanger ? Colors.redAccent : Colors.lightGreenAccent;
    
    // MAC Privacy Logic
    final sessionDuration = appState.connectionStartTime != null 
        ? DateTime.now().difference(appState.connectionStartTime!) 
        : Duration.zero;
    final isLongSession = sessionDuration.inMinutes >= 5;
    final macColor = isLongSession ? Colors.orangeAccent : Colors.cyanAccent;

    return _neonBox(
      color: isDanger ? Colors.redAccent : Colors.cyanAccent,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("STEALTH & PRIVACY HUB",
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              _buildCleanIdentityButton(appState),
            ],
          ),
          const SizedBox(height: 24),
          
          // IP Section
          _buildHubRow(
            icon: isDanger ? Icons.cell_wifi_rounded : Icons.airplanemode_active_rounded,
            color: networkColor,
            title: isDanger ? "IP RILEVABILE" : "SHIELD IP ATTIVO",
            subtitle: isDanger 
                ? "WiFi/Dati ON: IP ${appState.activeIpAddress ?? 'Rilevato'}. Rischio localizzazione." 
                : "Rete OFF. Nessun indirizzo IP esposto sulla rete locale.",
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          
          // MAC Section
          _buildHubRow(
            icon: Icons.fingerprint_rounded,
            color: macColor,
            title: "IDENTITÀ HARDWARE (MAC)",
            subtitle: isLongSession 
                ? "Sessione lunga (${sessionDuration.inMinutes}m): Rischio logging del MAC Address fisico." 
                : "Identità hardware protetta. MAC statico rilevabile ma non ancora loggato.",
            isWarning: isLongSession,
          ),
          
          const SizedBox(height: 24),
          
          // Educational Note
          _buildInfoNote(
            "Il MAC Address è un ID hardware fisso e non può essere cambiato senza Root. Spegni WiFi/Dati per l'anonimato IP; il Bluetooth HID è già isolato."
          ),
        ],
      ),
    ).animate().fadeIn(delay: 480.ms).slideY(begin: 0.2);
  }

  Widget _buildHubRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 10, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCleanIdentityButton(AppState appState) {
    return InkWell(
      onTap: () async {
        await appState.resetHidIdentity();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Identità Bluetooth Resettata e Cache Pulita ✓"),
              backgroundColor: Color(0xFF1A1A2E),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: const [
            Icon(Icons.refresh_rounded, color: Colors.cyanAccent, size: 12),
            SizedBox(width: 6),
            Text("CLEAN IDENTITY", style: TextStyle(color: Colors.cyanAccent, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white38, fontSize: 9, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildKeyboardLayoutSelector(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("LAYOUT TASTIERA TARGET",
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ),
              child: const Text("NEW", style: TextStyle(color: Colors.cyanAccent, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Scegli in base al layout HID del dispositivo TARGET",
          style: TextStyle(color: Colors.white24, fontSize: 9),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildLayoutOption(
              "PC IT",
              "Win/Mac\ntastiera IT",
              appState.activeLayout == KeyboardLayout.pc,
              () => appState.updateKeyboardLayout(KeyboardLayout.pc),
              Icons.computer_rounded,
              Colors.cyanAccent,
            ),
            const SizedBox(width: 8),
            _buildLayoutOption(
              "ANDROID IT",
              "Per tastiera IT\nfisica/alternativa",
              appState.activeLayout == KeyboardLayout.androidIt,
              () => appState.updateKeyboardLayout(KeyboardLayout.androidIt),
              Icons.android_rounded,
              Colors.greenAccent,
            ),
            const SizedBox(width: 8),
            _buildLayoutOption(
              "US INTL",
              "Standard US\nInternational",
              appState.activeLayout == KeyboardLayout.usInternational,
              () => appState.updateKeyboardLayout(KeyboardLayout.usInternational),
              null,
              Colors.deepPurpleAccent,
              imageAsset: 'assets/ui_shark_icon.png',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutOption(String label, String subtitle, bool isSelected, VoidCallback onTap, IconData? icon, Color accentColor, {String? imageAsset}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 10, spreadRadius: -2)
            ] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageAsset != null)
                Image.asset(imageAsset, width: 22, height: 22, color: isSelected ? accentColor : Colors.white38)
              else if (icon != null)
                Icon(icon, color: isSelected ? accentColor : Colors.white38, size: 18),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? accentColor.withValues(alpha: 0.7) : Colors.white24,
                  fontSize: 8,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
