import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';

// ─── YouTube URL Helpers ──────────────────────────────────────────────────────

/// Extracts the video ID from any YouTube URL format.
String? _extractVideoId(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    final seg = uri.pathSegments.firstOrNull;
    return (seg != null && seg.isNotEmpty) ? seg : null;
  }
  if (uri.host.contains('youtube.com')) {
    if (uri.queryParameters.containsKey('v')) return uri.queryParameters['v'];
    final segs = uri.pathSegments;
    if (segs.length >= 2 && (segs[0] == 'shorts' || segs[0] == 'embed')) return segs[1];
  }
  return null;
}

/// Extracts timestamp in seconds from a YouTube URL (t=123, t=1h2m3s, etc.)
int? _extractTimestamp(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return null;
  final tParam = uri.queryParameters['t'] ?? uri.queryParameters['start'];
  if (tParam == null) return null;
  final asInt = int.tryParse(tParam.replaceAll('s', ''));
  if (!tParam.contains(RegExp(r'[hm]')) && asInt != null) return asInt;
  int total = 0;
  final hMatch = RegExp(r'(\d+)h').firstMatch(tParam);
  final mMatch = RegExp(r'(\d+)m').firstMatch(tParam);
  final sMatch = RegExp(r'(\d+)s').firstMatch(tParam);
  if (hMatch != null) total += int.parse(hMatch.group(1)!) * 3600;
  if (mMatch != null) total += int.parse(mMatch.group(1)!) * 60;
  if (sMatch != null) total += int.parse(sMatch.group(1)!);
  return total > 0 ? total : null;
}

/// Formats seconds as mm:ss or h:mm:ss.
String _formatTime(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// ─── Main Editor Screen ───────────────────────────────────────────────────────

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
    final safeStart = selection.start.clamp(0, text.length);
    final safeEnd = selection.end.clamp(0, text.length);
    final newText = text.replaceRange(safeStart, safeEnd, cmd);
    _scriptController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: safeStart + cmd.length),
    );
    Provider.of<AppState>(context, listen: false).script = newText;
  }

  // ─── YouTube: open app then detect link ───────────────────────────────────
  void _showYouTubeDialog() {
    // 1. Open YouTube immediately in external app or browser
    launchUrl(
      Uri.parse('https://www.youtube.com'),
      mode: LaunchMode.externalApplication,
    );

    // 2. Show sheet that monitors lifecycle and clipboard
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _YouTubeLinkSheet(
        onInsert: _insertCommand,
      ),
    );
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
        children: [
          ...commands.map((cmd) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildFastButton(cmd),
            ),
          )),
          const SizedBox(width: 8),
          _buildYouTubeButton(),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildYouTubeButton() {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showYouTubeDialog();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF0000).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF0000).withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF4444), size: 18),
      ),
    );
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
          _buildNeonButton(
            onTap: () => _showSaveDialog(appState),
            color: Colors.greenAccent,
            icon: Icons.save_rounded,
            text: "SAVE",
            compact: true,
          ),
          const SizedBox(width: 12),
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

// ─── YouTube Link Sheet ───────────────────────────────────────────────────────
/// Shown after opening YouTube. Monitors app lifecycle to auto-detect a
/// YouTube URL from clipboard when the user returns from the YouTube app.
class _YouTubeLinkSheet extends StatefulWidget {
  final void Function(String cmd) onInsert;
  const _YouTubeLinkSheet({required this.onInsert});

  @override
  State<_YouTubeLinkSheet> createState() => _YouTubeLinkSheetState();
}

class _YouTubeLinkSheetState extends State<_YouTubeLinkSheet>
    with WidgetsBindingObserver {
  // null = waiting, non-null = parsed
  String? _videoId;
  int? _timestamp;
  bool _waiting = true; // show spinner while user is in YouTube

  final TextEditingController _timeController = TextEditingController();

  static const _kRed = Color(0xFFFF4444);
  static const _kRedDark = Color(0xFFFF0000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeController.dispose();
    super.dispose();
  }

  /// Called whenever the app comes back to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waiting) {
      _tryReadClipboard();
    }
  }

  Future<void> _tryReadClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    final id = _extractVideoId(text);
    if (id != null && mounted) {
      final ts = _extractTimestamp(text);
      setState(() {
        _videoId = id;
        _timestamp = ts;
        _waiting = false;
        if (ts != null) _timeController.text = _formatTime(ts);
      });
    }
  }

  // ── Computed URLs ──────────────────────────────────────────────────────────
  String? get _plainUrl => _videoId != null ? 'https://youtu.be/$_videoId' : null;

  String? get _timestampUrl {
    if (_videoId == null) return null;
    int? secs = _timestamp;
    if (secs == null && _timeController.text.isNotEmpty) {
      final parts = _timeController.text.split(':');
      if (parts.length == 2) {
        secs = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      } else if (parts.length == 3) {
        secs = (int.tryParse(parts[0]) ?? 0) * 3600 +
               (int.tryParse(parts[1]) ?? 0) * 60 +
               (int.tryParse(parts[2]) ?? 0);
      }
    }
    if (secs == null || secs <= 0) return null;
    return 'https://youtu.be/$_videoId?t=$secs';
  }

  void _insert(String url) {
    widget.onInsert('STRING $url\nENTER\n');
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kRed.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: _kRedDark.withValues(alpha: 0.12),
              blurRadius: 30,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kRedDark.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_circle_filled_rounded,
                      color: _kRed, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUTUBE LINK',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    Text(
                      _waiting
                          ? 'In attesa del link...'
                          : 'Link rilevato ✓',
                      style: TextStyle(
                          color: _waiting ? Colors.white38 : const Color(0xFF4CAF50),
                          fontSize: 10),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white38, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Waiting state ──
            if (_waiting) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kRed),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vai al video su YouTube',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text(
                            'Premi Condividi → Copia link, poi torna qui',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Manual paste fallback
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _tryReadClipboard,
                  icon: const Icon(Icons.content_paste_rounded,
                      color: _kRed, size: 16),
                  label: const Text('Incolla dagli appunti',
                      style: TextStyle(
                          color: _kRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _kRed.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // ── Link options (shown after detection) ──
            if (!_waiting && _videoId != null) ...[
              // Video ID badge
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50), size: 13),
                  const SizedBox(width: 6),
                  Text('Video ID: $_videoId',
                      style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  if (_timestamp != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded,
                        color: Colors.white38, size: 12),
                    const SizedBox(width: 4),
                    Text('timestamp: ${_formatTime(_timestamp!)}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Option 1 — plain URL
              _LinkOptionTile(
                icon: Icons.link_rounded,
                label: 'Copia URL video',
                enabled: _plainUrl != null,
                onTap: _plainUrl != null ? () => _insert(_plainUrl!) : null,
              ),
              const SizedBox(height: 10),

              // Option 2 — URL with timestamp
              _LinkOptionTile(
                icon: Icons.access_time_rounded,
                label: "Copia l'URL del video in corrispondenza del minuto corrente",
                enabled: _timestampUrl != null,
                onTap: _timestampUrl != null ? () => _insert(_timestampUrl!) : null,
              ),

              // Manual time input if no timestamp in URL
              if (_timestamp == null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.edit_rounded,
                        color: Colors.white38, size: 13),
                    const SizedBox(width: 6),
                    const Text('Inserisci il minuto manualmente:',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _timeController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      hintText: 'mm:ss',
                      hintStyle:
                          const TextStyle(color: Colors.white24, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kRed),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Link Option Tile ─────────────────────────────────────────────────────────
class _LinkOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _LinkOptionTile({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const kRed = Color(0xFFFF4444);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? kRed.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: enabled ? kRed : Colors.white24, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (enabled)
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
