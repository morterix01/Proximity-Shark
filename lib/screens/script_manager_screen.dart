import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_state.dart';

class ScriptManagerScreen extends StatelessWidget {
  const ScriptManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final scripts = appState.savedScripts;

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
                _buildImportCard(appState),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                  child: Text("STORED PAYLOADS", style: TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                ),
                Expanded(child: _buildScriptList(appState, scripts)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundLayers() {
    return Positioned(
      top: 100, left: -50,
      child: Container(
        width: 300, height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.amberAccent.withValues(alpha: 0.05),
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .blur(begin: const Offset(50, 50), end: const Offset(90, 90), duration: 15.seconds),
    );
  }

  Widget _buildHeader(AppState appState) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "LIBRARY HUB",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0),
          ),
          Text(
            "CENTRAL PAYLOAD REPOSITORY",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amberAccent, letterSpacing: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildImportCard(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: InkWell(
        onTap: appState.importScript,
        borderRadius: BorderRadius.circular(18),
        child: _buildNeonContainer(
          color: Colors.amberAccent,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.file_upload_rounded, color: Colors.amberAccent),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("IMPORT PAYLOAD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.1)),
                    Text("UPLOAD .TXT FROM DEVICE", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildScriptList(AppState appState, List<File> scripts) {
    if (scripts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 60, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 12),
            const Text("NO SCRIPTS FOUND", style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: scripts.length,
      itemBuilder: (context, index) {
        final file = scripts[index];
        final name = file.path.split('/').last.replaceAll('.txt', '');
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildScriptItem(context, name, file, appState),
        );
      },
    );
  }

  Widget _buildScriptItem(BuildContext context, String name, File file, AppState appState) {
    return _buildNeonContainer(
      color: Colors.white12,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                Text("${file.lengthSync()} BYTES", style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.amberAccent, size: 20),
            onPressed: () {
              if (appState.connectionStatus == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ERRORE: Non connesso!")),
                );
                return;
              }
              appState.deployScript(file);
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_open_rounded, color: Colors.cyanAccent, size: 18),
            onPressed: () {
              appState.loadScriptFromFile(file);
              appState.currentNavIndex = 2; // Go to Editor
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
            onPressed: () => appState.deleteScript(file),
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
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
