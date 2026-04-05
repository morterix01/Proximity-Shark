import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';

class QuickEditorScreen extends StatefulWidget {
  const QuickEditorScreen({super.key});

  @override
  State<QuickEditorScreen> createState() => _QuickEditorScreenState();
}

class _QuickEditorScreenState extends State<QuickEditorScreen> {
  late TextEditingController _scriptController;
  String _lastKnownScript = '';

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _lastKnownScript = appState.script;
    _scriptController = TextEditingController(text: appState.script);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync editor when AppState.script changes externally (e.g. loaded from Library)
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.script != _lastKnownScript && appState.script != _scriptController.text) {
      _lastKnownScript = appState.script;
      _scriptController.value = TextEditingValue(
        text: appState.script,
        selection: TextSelection.collapsed(offset: appState.script.length),
      );
    }
  }

  @override
  void dispose() {
    _scriptController.dispose();
    super.dispose();
  }

  void _insertCommand(String cmd) {
    final text = _scriptController.text;
    final selection = _scriptController.selection;
    final newText = text.replaceRange(selection.start, selection.end, cmd);
    _scriptController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + cmd.length),
    );
    Provider.of<AppState>(context, listen: false).script = newText;
  }

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
              children: [
                _buildHeader(),
                _buildFastEditorBar(),
                Expanded(child: _buildEditor(appState)),
                _buildActionButtons(appState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundLayers() {
    return Positioned(
      bottom: -100, left: -100,
      child: Container(
        width: 350, height: 350,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.cyanAccent.withValues(alpha: 0.05),
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .blur(begin: const Offset(60, 60), end: const Offset(100, 100), duration: 12.seconds),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SCRIPTS EDITOR",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0),
              ),
              Text(
                "PAYLOAD AUTHORING CONSOLE",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1.5),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildFastEditorBar() {
    final commands = ["GUI ", "DELAY ", "STRING "];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: commands.map((cmd) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildFastButton(cmd),
          ),
        )).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildFastButton(String cmd) {
    return InkWell(
      onTap: () => _insertCommand(cmd),
      onTapDown: (_) => HapticFeedback.mediumImpact(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            cmd.trim(),
            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(AppState appState) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: TextField(
          controller: _scriptController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.cyanAccent, height: 1.5),
          decoration: InputDecoration(
            hintText: "// DIGITARE COMANDI QUI...",
            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(20),
          ),
          onChanged: (val) => appState.script = val,
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.98, 0.98));
  }

  Widget _buildActionButtons(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildNeonButton(
              onTap: appState.isExecuting ? null : () {
                if (appState.connectionStatus == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ERRORE: Dispositivo non connesso!")),
                  );
                  return;
                }
                appState.runScript();
              },
              color: Colors.cyanAccent,
              icon: Icons.bolt_rounded,
              text: "EXECUTE",
              isLoading: appState.isExecuting,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildNeonButton({
    required VoidCallback? onTap,
    required Color color,
    required IconData icon,
    required String text,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: -2),
            ],
          ),
          child: Center(
            child: isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
