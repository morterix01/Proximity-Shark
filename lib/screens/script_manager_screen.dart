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
                _buildActionButtons(context, appState),
                if (appState.isImporting)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                    ),
                  ),
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

  // Replaced _buildImportCard with _buildActionButtons
  Widget _buildActionButtons(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: appState.isImporting ? null : () async {
                    await appState.importScript();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Import completed")),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: _buildNeonContainer(
                    color: appState.isImporting ? Colors.white10 : Colors.amberAccent,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Icon(Icons.file_copy_rounded, color: appState.isImporting ? Colors.white24 : Colors.amberAccent, size: 20),
                        const SizedBox(height: 4),
                        const Text("FILES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: appState.isImporting ? null : () async {
                    await appState.importFolder();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Folder import finished")),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: _buildNeonContainer(
                    color: appState.isImporting ? Colors.white10 : Colors.cyanAccent,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Icon(Icons.drive_folder_upload_rounded, color: appState.isImporting ? Colors.white24 : Colors.cyanAccent, size: 20),
                        const SizedBox(height: 4),
                        const Text("FOLDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _showCreateFolderDialog(context, appState),
                  borderRadius: BorderRadius.circular(18),
                  child: _buildNeonContainer(
                    color: Colors.greenAccent,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.create_new_folder_rounded, color: Colors.greenAccent, size: 20),
                        const SizedBox(height: 4),
                        const Text("NEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
    );
  }

  void _showCreateFolderDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("NEW FOLDER", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Folder name...",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              appState.createFolder(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text("CREATE", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptList(AppState appState, List<FileSystemEntity> scripts) {
    final showUpLevel = !appState.isRootDirectory;
    final itemCount = scripts.length + (showUpLevel ? 1 : 0);

    if (itemCount == 0) {
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
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (showUpLevel && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: appState.navigateUp,
              child: _buildNeonContainer(
                color: Colors.white24,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_upward_rounded, color: Colors.white38, size: 20),
                    SizedBox(width: 16),
                    Text("UP TO PARENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        }

        final actualIndex = showUpLevel ? index - 1 : index;
        final fileOrDir = scripts[actualIndex];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: fileOrDir is Directory
              ? _buildDirectoryItem(context, fileOrDir, appState)
              : _buildScriptItem(context, fileOrDir as File, appState),
        );
      },
    );
  }

  Widget _buildDirectoryItem(BuildContext context, Directory dir, AppState appState) {
    final name = dir.path.split(Platform.pathSeparator).last;
    return InkWell(
      onTap: () => appState.navigateIntoFolder(dir),
      child: _buildNeonContainer(
        color: Colors.greenAccent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.folder_rounded, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
              onPressed: () => _deleteEntity(context, appState, dir),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 50.ms).slideX(begin: 0.1);
  }

  Widget _buildScriptItem(BuildContext context, File file, AppState appState) {
    final name = file.path.split(Platform.pathSeparator).last.replaceAll('.txt', '');
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
            onPressed: () async {
              // Navigate to editor first, then update script on next frame
              appState.currentNavIndex = 2;
              await Future.microtask(() => appState.loadScriptFromFile(file));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
            onPressed: () => _deleteEntity(context, appState, file),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1);
  }

  void _deleteEntity(BuildContext context, AppState appState, FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete ${entity.path.split(Platform.pathSeparator).last}?", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (entity is File) {
                appState.deleteScript(entity);
              } else if (entity is Directory) {
                entity.deleteSync(recursive: true);
                appState.navigateIntoFolder(appState.currentDirectory!); // Reload
              }
              Navigator.pop(ctx);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
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
