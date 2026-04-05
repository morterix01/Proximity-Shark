import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TextEditingController _scriptController;
  late TextEditingController _nameController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _scriptController = TextEditingController(text: appState.script);
    _nameController = TextEditingController(text: appState.bleName);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _scriptController.dispose();
    _nameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Deep Background
          Container(color: const Color(0xFF0A0A12)),
          
          // Animated Background Orbs
          _buildAnimatedGlow(
            top: -50, 
            right: -50, 
            color: Colors.cyanAccent, 
            duration: 8.seconds,
            begin: const Offset(-20, -20),
            end: const Offset(40, 20),
          ),
          _buildAnimatedGlow(
            bottom: 50, 
            left: -100, 
            color: Colors.blueAccent, 
            duration: 12.seconds,
            begin: const Offset(30, 40),
            end: const Offset(-30, -30),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                  child: _buildHeader(context),
                ),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEditorTab(context),
                      _buildLibraryTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedGlow({
    double? top, double? bottom, double? left, double? right, 
    required Color color, required Duration duration,
    required Offset begin, required Offset end,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .move(begin: begin, end: end, duration: duration, curve: Curves.easeInOut)
       .blur(begin: const Offset(80, 80), end: const Offset(120, 120)),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final status = context.watch<AppState>().connectionStatus;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PROXIMITY SHARK",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ).animate().fadeIn().slideX(begin: -0.2),
            Text(
              "HID CONTROL UNIT // VER 2.1",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent.withValues(alpha: 0.7),
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
        _buildStatusIndicator(status).animate().scale(delay: 400.ms),
      ],
    );
  }

  Widget _buildStatusIndicator(int status) {
    final isConnected = status == 1;
    final color = isConnected ? Colors.greenAccent : Colors.redAccent;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color, blurRadius: 8, spreadRadius: 1)],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds),
          const SizedBox(width: 10),
          Text(
            isConnected ? "ONLINE" : "OFFLINE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [Colors.cyanAccent.withValues(alpha: 0.3), Colors.blueAccent.withValues(alpha: 0.3)],
          ),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 1.5),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
        unselectedLabelColor: Colors.white38,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "TERMINAL"),
          Tab(text: "DATABASE"),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildEditorTab(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildBleNameSettings(appState).animate().fadeIn(delay: 600.ms).slideX(),
          const SizedBox(height: 16),
          Expanded(child: _buildEditor(appState).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.95, 0.95))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSaveButton(appState).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2)),
              const SizedBox(width: 12),
              Expanded(child: _buildRunButton(appState).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2)),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBleNameSettings(AppState appState) {
    return _buildNeonContainer(
      color: Colors.blueAccent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected_rounded, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: "SET SYSTEM IDENTIFIER",
                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              appState.updateBleName(_nameController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ID AGGIORNATO"), backgroundColor: Colors.blueAccent),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("APPLY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(AppState appState) {
    return _buildNeonContainer(
      color: Colors.cyanAccent,
      child: TextField(
        controller: _scriptController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 15, color: Colors.cyanAccent, height: 1.5),
        decoration: InputDecoration(
          hintText: "// DIGITARE COMANDI QUI...",
          hintStyle: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        onChanged: (val) => appState.script = val,
      ),
    );
  }

  Widget _buildSaveButton(AppState appState) {
    return _buildNeonButton(
      onTap: () => _showSaveDialog(context, appState),
      icon: Icons.archive_rounded,
      text: "STORE",
      color: Colors.white10,
      iconColor: Colors.amberAccent,
    );
  }

  Widget _buildRunButton(AppState appState) {
    return _buildNeonButton(
      onTap: appState.isExecuting ? null : () => appState.runScript(),
      icon: Icons.bolt_rounded,
      text: "EXECUTE",
      gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
      iconColor: Colors.white,
      isLoading: appState.isExecuting,
    );
  }

  Widget _buildLibraryTab(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final scripts = appState.savedScripts;

    if (scripts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 80, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
            const Text("NO DATA DETECTED", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ).animate().fadeIn().scale(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: scripts.length,
      itemBuilder: (context, index) {
        final file = scripts[index];
        final name = file.path.split('/').last.replaceAll('.txt', '');
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildLibraryItem(name, file, appState, index),
        );
      },
    );
  }

  Widget _buildLibraryItem(String name, File file, AppState appState, int index) {
    return _buildNeonContainer(
      color: Colors.white12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded, color: Colors.cyanAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                Text("TEXT/PLAIN • ${file.lengthSync()} BYTES", style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _buildCircleIconBtn(
            icon: Icons.file_upload_rounded, 
            color: Colors.greenAccent, 
            onPressed: () {
              appState.loadScriptFromFile(file);
              _scriptController.text = appState.script;
              _tabController.animateTo(0);
            }
          ),
          const SizedBox(width: 8),
          _buildCircleIconBtn(
            icon: Icons.delete_forever_rounded, 
            color: Colors.redAccent, 
            onPressed: () => appState.deleteScript(file)
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2, curve: Curves.easeOutCubic);
  }

  Widget _buildCircleIconBtn({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildNeonContainer({required Widget child, required Color color, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 15, spreadRadius: -5),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildNeonButton({
    required VoidCallback? onTap,
    required IconData icon,
    required String text,
    Color? color,
    Color? iconColor,
    Gradient? gradient,
    bool isLoading = false,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color,
        gradient: gradient,
        boxShadow: gradient != null ? [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: -2),
        ] : null,
        border: gradient == null ? Border.all(color: Colors.white10) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: iconColor, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        text, 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => isLoading ? c.repeat() : c.stop()).shimmer(duration: 2.seconds, color: Colors.white24);
  }

  void _showSaveDialog(BuildContext context, AppState appState) {
    final diagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF14141E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
          title: const Text("SALVATAGGIO DATI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
          content: TextField(
            controller: diagController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "NOME IDENTIFICATIVO",
              hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold))
            ),
            _buildNeonButton(
              onTap: () {
                if (diagController.text.isNotEmpty) {
                  appState.saveCurrentScript(diagController.text);
                  Navigator.pop(context);
                }
              },
              icon: Icons.check_circle_rounded,
              text: "SAVE",
              gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.tealAccent]),
              iconColor: Colors.white,
            ).animate().scale(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
