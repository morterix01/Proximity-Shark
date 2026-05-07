import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

  Future<void> _sendMessage(String text, SharkChatManager chat) async {
    if (text.trim().isEmpty) return;
    _textCtrl.clear();
    setState(() => _showQuickMessages = false);
    await chat.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: SharkChatManager(),
      child: Consumer<SharkChatManager>(
        builder: (context, chat, _) {
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
        },
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
                  ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 6)]
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
        // Toggle chat on/off
        IconButton(
          icon: Icon(chat.isRunning ? Icons.wifi_tethering_off : Icons.wifi_tethering,
              color: chat.isRunning ? Colors.greenAccent : Colors.grey),
          tooltip: chat.isRunning ? 'Interrompi Chat' : 'Avvia Chat',
          onPressed: () async {
            if (chat.isRunning) {
              await chat.stop();
            } else {
              // Get device name from system
              const platform = MethodChannel('com.luis.ducky_android/hid');
              String name = 'Shark';
              try {
                name = await platform.invokeMethod('getDeviceName') ?? 'Shark';
              } catch (_) {}
              await chat.start(name);
            }
          },
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
    if (peers.isEmpty && !chat.isRunning) {
      return Container(
        padding: const EdgeInsets.all(10),
        color: _surfaceColor,
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 16),
            const SizedBox(width: 8),
            Text(
              'Premi ▶ per avviare la ricerca di dispositivi Shark',
              style: GoogleFonts.exo2(color: Colors.grey, fontSize: 12),
            ),
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (peers.isEmpty) {
             return Center(
               child: Row(
                 children: [
                   const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
                   const SizedBox(width: 8),
                   Text('Ricerca dispositivi Shark...', style: GoogleFonts.exo2(color: Colors.grey, fontSize: 11)),
                 ],
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
                border: Border.all(color: isConnected ? Colors.greenAccent.withOpacity(0.5) : Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? Colors.greenAccent : Colors.grey,
                      boxShadow: isConnected ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 4)] : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    peer.name,
                    style: GoogleFonts.exo2(fontSize: 12, color: isConnected ? Colors.white : Colors.grey, fontWeight: isConnected ? FontWeight.bold : FontWeight.normal),
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final msg = _quickMessages[i];
          return ActionChip(
            label: Text(msg, style: const TextStyle(fontSize: 13)),
            backgroundColor: _sharkBlue.withOpacity(0.2),
            side: BorderSide(color: _sharkBlue.withOpacity(0.4)),
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
            Icon(Icons.chat_bubble_outline, color: _sharkBlue.withOpacity(0.3), size: 64),
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
                backgroundColor: _sharkBlue.withOpacity(0.2),
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
                    color: (isOwn ? _sharkBlue : Colors.black).withOpacity(0.15),
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
                      color: Colors.white.withOpacity(0.5),
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
    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                enabled: chat.isRunning,
                style: GoogleFonts.exo2(color: Colors.white),
                decoration: InputDecoration(
                  hintText: chat.isRunning
                      ? 'Scrivi un messaggio...'
                      : 'Avvia la chat prima di scrivere',
                  hintStyle: GoogleFonts.exo2(color: Colors.grey),
                  filled: true,
                  fillColor: _cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: _sharkBlue.withOpacity(0.6)),
                  ),
                ),
                onSubmitted: (text) => _sendMessage(text, chat),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0055AA), _sharkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _sharkBlue.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: chat.isRunning
                    ? () => _sendMessage(_textCtrl.text, chat)
                    : null,
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
