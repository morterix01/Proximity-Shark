import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../chat/chat_message.dart';
import '../chat/shark_chat_manager.dart';

class SharkChatScreen extends StatefulWidget {
  const SharkChatScreen({super.key});

  @override
  State<SharkChatScreen> createState() => _SharkChatScreenState();
}

class _SharkChatScreenState extends State<SharkChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _showQuickMessages = false;
  bool _isStarting = false; // loading state while requesting permissions

  static const _quickMessages = [
    '✅ Ok',
    '❌ No',
    '⏳ Aspetta',
    '🚨 Attenzione!',
    '👍 Fatto',
    '📍 Sono qui',
    '🤫 Silenzio',
    '🔄 Riprova',
    '⚡ Urgente',
    '🛑 Stop',
  ];

  static const _sharkBlue = Color(0xFF00B0FF);
  static const _bgColor = Color(0xFF0A0A0F);
  static const _surfaceColor = Color(0xFF12121A);
  static const _cardColor = Color(0xFF1A1A27);

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleChat(SharkChatManager chat) async {
    if (chat.isRunning) {
      await chat.stop();
      if (mounted) setState(() => _isStarting = false);
      return;
    }

    // Show loading state immediately so user sees feedback
    if (mounted) setState(() => _isStarting = true);

    // Capture context-dependent values BEFORE any async gap
    final appState = Provider.of<AppState>(context, listen: false);
    final scaffoldMsg = ScaffoldMessenger.of(context);

    try {
      // 1. Ensure Bluetooth is actually enabled on the device
      final platform = MethodChannel('com.luis.ducky_android/hid');
      try {
        final bool isBtOn = await platform.invokeMethod('isBluetoothEnabled') ?? false;
        if (!isBtOn) {
          if (mounted) {
            setState(() => _isStarting = false);
            scaffoldMsg.showSnackBar(
              const SnackBar(
                content: Text('Bluetooth disattivato. Accendilo per usare la Shark Chat.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
          return;
        }
      } catch (_) {
        // If method channel fails, proceed and let Nearby handle it
      }

      // 2. Request permissions — only CRITICAL ones block the chat.
      // nearbyWifiDevices is optional: missing on older Android, may be restricted.
      final criticalPermissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.locationWhenInUse,
      ];

      // Request nearbyWifiDevices separately (best-effort, non-blocking)
      try {
        await Permission.nearbyWifiDevices.request();
      } catch (_) {}

      final statuses = await criticalPermissions.request();

      // Only fail if a truly critical permission is permanently denied
      final permanentlyDenied = statuses.values.any((s) => s.isPermanentlyDenied);
      // Consider 'restricted' (iOS) as granted equivalent
      final denied = statuses.values.any(
        (s) => s.isDenied || s.isPermanentlyDenied,
      );

      if (denied) {
        if (mounted) {
          setState(() => _isStarting = false);
          scaffoldMsg.showSnackBar(
            SnackBar(
              content: Text(permanentlyDenied
                  ? 'Apri Impostazioni e abilita Bluetooth e Posizione per Proximity Shark.'
                  : 'Permessi Bluetooth e Posizione necessari. Concedili e riprova.'),
              backgroundColor: Colors.redAccent,
              action: permanentlyDenied
                  ? SnackBarAction(
                      label: 'Impostazioni',
                      textColor: Colors.white,
                      onPressed: openAppSettings,
                    )
                  : null,
            ),
          );
        }
        return;
      }

      // 3. Start chat with the configured name
      final name = appState.bleName.isNotEmpty ? appState.bleName : 'Shark';
      await chat.start(name);
    } catch (e) {
      debugPrint('[SharkChat] _toggleChat error: $e');
    } finally {
      // Always reset the loading state, even on error
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _sendMessage(String text, SharkChatManager chat) async {
    if (text.trim().isEmpty) return;
    _textCtrl.clear();
    setState(() => _showQuickMessages = false);
    await chat.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // Recuperiamo l'istanza esistente dal provider globale
    final chat = Provider.of<SharkChatManager>(context);
    _scrollToBottom();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(chat),
      body: Column(
        children: [
          _buildPeerStatus(chat),
          if (_showQuickMessages) _buildQuickMessages(chat),
          Expanded(child: _buildMessageList(chat)),
          _buildInputBar(chat),
        ],
      ),
    );
  }

  AppBar _buildAppBar(SharkChatManager chat) {
    return AppBar(
      backgroundColor: _surfaceColor,
      title: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: chat.isRunning ? Colors.greenAccent : Colors.redAccent,
              boxShadow: chat.isRunning
                  ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Shark Chat',
            style: GoogleFonts.exo2(
              fontWeight: FontWeight.bold,
              color: _sharkBlue,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        if (_isStarting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _sharkBlue)),
          )
        else
          IconButton(
            icon: Icon(chat.isRunning ? Icons.wifi_tethering_off : Icons.wifi_tethering,
                color: chat.isRunning ? Colors.greenAccent : Colors.grey),
            tooltip: chat.isRunning ? 'Interrompi Chat' : 'Avvia Chat',
            onPressed: () => _toggleChat(chat),
          ),
        IconButton(
          icon: const Icon(Icons.flash_on, color: _sharkBlue),
          tooltip: 'Messaggi Rapidi',
          onPressed: () => setState(() => _showQuickMessages = !_showQuickMessages),
        ),
      ],
    );
  }

  Widget _buildPeerStatus(SharkChatManager chat) {
    final peers = chat.discoveredPeers;
    if (!chat.isRunning && !_isStarting) {
      // Stopped state — big tappable banner to start
      return Material(
        color: _surfaceColor,
        child: InkWell(
          onTap: () => _toggleChat(chat),
          splashColor: _sharkBlue.withValues(alpha: 0.2),
          highlightColor: _sharkBlue.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.wifi_tethering, color: _sharkBlue, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ricerca Shark DISATTIVATA',
                        style: GoogleFonts.exo2(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tocca qui per cercare dispositivi nelle vicinanze',
                        style: GoogleFonts.exo2(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_arrow_rounded, color: Colors.greenAccent),
              ],
            ),
          ),
        ),
      );
    }

    if (_isStarting) {
      // Loading state while requesting permissions
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: _surfaceColor,
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _sharkBlue)),
            const SizedBox(width: 12),
            Text('Avvio ricerca in corso...', style: GoogleFonts.exo2(color: Colors.white, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      height: 48,
      color: _surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: peers.isEmpty ? 1 : peers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (peers.isEmpty) {
             return Center(
               child: InkWell(
                 onTap: () => _toggleChat(chat),
                 borderRadius: BorderRadius.circular(20),
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: _sharkBlue)),
                       const SizedBox(width: 10),
                       Text('Ricerca in corso...', style: GoogleFonts.exo2(color: Colors.white, fontSize: 12)),
                       const SizedBox(width: 8),
                       const Icon(Icons.stop_circle, color: Colors.redAccent, size: 18),
                     ],
                   ),
                 ),
               ),
             );
          }
          final peer = peers[i];
          final isConnected = peer.isConnected;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isConnected ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? Colors.greenAccent : Colors.grey,
                      boxShadow: isConnected ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 4)] : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer.name,
                        style: GoogleFonts.exo2(
                          fontSize: 12, 
                          color: isConnected ? Colors.white : Colors.grey, 
                          fontWeight: isConnected ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                      if (isConnected)
                        Text(
                          'CONNESSO',
                          style: GoogleFonts.exo2(fontSize: 7, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickMessages(SharkChatManager chat) {
    return Container(
      height: 60,
      color: _cardColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _quickMessages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final msg = _quickMessages[i];
          return ActionChip(
            label: Text(msg, style: const TextStyle(fontSize: 13)),
            backgroundColor: _sharkBlue.withValues(alpha: 0.2),
            side: BorderSide(color: _sharkBlue.withValues(alpha: 0.4)),
            onPressed: () => _sendMessage(msg, chat),
          );
        },
      ),
    );
  }

  Widget _buildMessageList(SharkChatManager chat) {
    if (chat.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: _sharkBlue.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 12),
            Text(
              'Nessun messaggio ancora\nAvvia la chat per trovare dispositivi vicini',
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: chat.messages.length,
      itemBuilder: (_, i) => _buildBubble(chat.messages[i]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isOwn = msg.isOwn;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isOwn ? 64 : 0,
        right: isOwn ? 0 : 64,
      ),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: _sharkBlue.withValues(alpha: 0.2),
                child: Text(
                  msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                  style: const TextStyle(color: _sharkBlue, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isOwn
                    ? const LinearGradient(
                        colors: [Color(0xFF0077CC), Color(0xFF00B0FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isOwn ? null : _cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwn ? 18 : 4),
                  bottomRight: Radius.circular(isOwn ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isOwn ? _sharkBlue : Colors.black).withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isOwn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        msg.senderName,
                        style: GoogleFonts.exo2(
                          color: _sharkBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    msg.text,
                    style: GoogleFonts.exo2(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(msg.timestamp),
                    style: GoogleFonts.exo2(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(SharkChatManager chat) {
    // Input is enabled as soon as the chat is running (even without connected peers)
    final canSend = chat.isRunning;
    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                enabled: canSend,
                style: GoogleFonts.exo2(color: Colors.white),
                decoration: InputDecoration(
                  hintText: canSend
                      ? (chat.connectedPeers.isNotEmpty
                          ? 'Invia ai dispositivi connessi...'
                          : 'In attesa di dispositivi Shark...')
                      : 'Attiva la ricerca per scrivere',
                  hintStyle: GoogleFonts.exo2(color: Colors.grey),
                  filled: true,
                  fillColor: canSend ? _cardColor : _cardColor.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: _sharkBlue.withValues(alpha: 0.6)),
                  ),
                ),
                onSubmitted: (text) => _sendMessage(text, chat),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: canSend
                    ? const LinearGradient(
                        colors: [Color(0xFF0055AA), _sharkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: canSend ? null : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                boxShadow: canSend
                    ? [BoxShadow(color: _sharkBlue.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: IconButton(
                icon: Icon(Icons.send_rounded, color: canSend ? Colors.white : Colors.grey),
                onPressed: canSend ? () => _sendMessage(_textCtrl.text, chat) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
