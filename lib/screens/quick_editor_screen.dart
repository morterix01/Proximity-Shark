import 'dart:io';
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
    final appState = Provider.of<AppState>(context);
    if (appState.script != _lastKnownScript) {
      _lastKnownScript = appState.script;
      if (_scriptController.text != appState.script) {
        _scriptController.value = TextEditingValue(
          text: appState.script,
          selection: TextSelection.collapsed(offset: appState.script.length),
        );
      }
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
          // SAVE button
          _buildNeonButton(
            onTap: () => _showSaveDialog(appState),
            color: Colors.greenAccent,
            icon: Icons.save_rounded,
            text: "SAVE",
            compact: true,
          ),
          const SizedBox(width: 12),
          // EXECUTE button
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

  void _showSaveDialog(AppState appState) {
    final nameController = TextEditingController();
    Directory? selectedFolder;
    List<Directory> folders = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Load folders on first render
          if (folders.isEmpty) {
            appState.getLibraryFolders().then((result) {
              setDialogState(() {
                folders = result;
                selectedFolder = result.isNotEmpty ? result.first : null;
              });
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.save_rounded, color: Colors.greenAccent, size: 20),
                SizedBox(width: 8),
                Text("SAVE TO LIBRARY", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SCRIPT NAME", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "my_payload",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.greenAccent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                if (folders.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text("DESTINATION FOLDER", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                    ),
                    child: DropdownButton<Directory>(
                      value: selectedFolder,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1A2E),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: folders.map((dir) {
                        final parts = dir.path.split(Platform.pathSeparator);
                        final label = parts.last == 'scripts' ? '/ (Root)' : parts.last;
                        return DropdownMenuItem<Directory>(
                          value: dir,
                          child: Text(label, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (dir) => setDialogState(() => selectedFolder = dir),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final target = selectedFolder;
                  Navigator.pop(ctx);
                  await appState.saveScriptTo(name, target ?? appState.currentDirectory!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                            const SizedBox(width: 8),
                            Text("'$name' salvato nella libreria!"),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1A1A2E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: const Text("SAVE", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNeonButton({
    required VoidCallback? onTap,
    required Color color,
    required IconData icon,
    required String text,
    bool isLoading = false,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: compact ? const EdgeInsets.symmetric(horizontal: 20) : null,
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
