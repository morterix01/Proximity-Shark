import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

import 'chat_message.dart';

/// Service ID used to identify Proximity Shark chat nodes in Nearby Connections.
const _kServiceId = 'com.luis.ducky_android.chat';

/// SharkChatManager — singleton that handles P2P offline chat via Google Nearby Connections.
///
/// Architecture:
///   - Advertises this device to nearby peers
///   - Discovers nearby peers
///   - Maintains a list of connected peers
///   - Broadcasts messages to all connected peers
///   - Notifies the UI via callbacks
class SharkChatManager extends ChangeNotifier {
  static final SharkChatManager _instance = SharkChatManager._internal();
  factory SharkChatManager() => _instance;
  SharkChatManager._internal();

  // ── State ──────────────────────────────────────────────────────────────────
  final List<ChatMessage> messages = [];
  final Map<String, ChatPeer> _peers = {}; // endpointId → ChatPeer
  bool _isRunning = false;

  List<ChatPeer> get connectedPeers =>
      _peers.values.where((p) => p.isConnected).toList();

  List<ChatPeer> get discoveredPeers => _peers.values.toList();

  bool get isRunning => _isRunning;

  /// Called whenever messages or peers change, so the watch can be updated.
  VoidCallback? onStateChangedForWatch;

  // ── Local device identity ───────────────────────────────────────────────────
  late String _localName;

  void setLocalName(String name) {
    _localName = name;
  }

  // ── Start / Stop ────────────────────────────────────────────────────────────
  Future<void> start(String deviceName) async {
    if (_isRunning) return;
    _localName = deviceName;
    _isRunning = true;

    try {
      // Start advertising so others can find us
      await Nearby().startAdvertising(
        _localName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _kServiceId,
      );

      // Start discovering other Proximity Shark instances
      await Nearby().startDiscovery(
        _localName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _kServiceId,
      );

      debugPrint('[SharkChat] Started advertising and discovery as $_localName');
    } catch (e) {
      debugPrint('[SharkChat] Error starting: $e');
      _isRunning = false;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    try {
      await Nearby().stopAllEndpoints();
      await Nearby().stopDiscovery();
      await Nearby().stopAdvertising();
    } catch (e) {
      debugPrint('[SharkChat] Error stopping: $e');
    }
    _peers.clear();
    _isRunning = false;
    notifyListeners();
  }

  // ── Send Message ────────────────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final msg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}',
      senderId: _localName,
      senderName: _localName,
      text: text.trim(),
      timestamp: DateTime.now(),
      isOwn: true,
    );

    // Add to local list immediately
    messages.add(msg);
    notifyListeners();
    onStateChangedForWatch?.call();

    // Broadcast to all connected peers
    final payload = msg.toJson();
    final bytes = utf8.encode(payload);

    for (final peer in connectedPeers) {
      try {
        await Nearby().sendBytesPayload(peer.endpointId, Uint8List.fromList(bytes));
      } catch (e) {
        debugPrint('[SharkChat] Error sending to ${peer.endpointId}: $e');
      }
    }
  }

  // ── Nearby Callbacks ────────────────────────────────────────────────────────
  void _onEndpointFound(String endpointId, String endpointName, String serviceId) {
    debugPrint('[SharkChat] Found: $endpointId ($endpointName)');
    if (!_peers.containsKey(endpointId)) {
      _peers[endpointId] = ChatPeer(endpointId: endpointId, name: endpointName);
      notifyListeners();
    }
    // Automatically request connection to new peers
    Nearby().requestConnection(
      _localName,
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  void _onEndpointLost(String? endpointId) {
    if (endpointId == null) return;
    debugPrint('[SharkChat] Lost: $endpointId');
    _peers.remove(endpointId);
    notifyListeners();
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    debugPrint('[SharkChat] Connection initiated with $endpointId (${info.endpointName})');
    // Update peer name from connection info
    _peers[endpointId] = ChatPeer(endpointId: endpointId, name: info.endpointName);
    // Auto-accept all connections from other Proximity Shark instances
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
    );
    notifyListeners();
  }

  void _onConnectionResult(String endpointId, Status status) {
    debugPrint('[SharkChat] Connection result $endpointId: $status');
    if (_peers.containsKey(endpointId)) {
      _peers[endpointId]!.isConnected = (status == Status.CONNECTED);
      notifyListeners();
      onStateChangedForWatch?.call();
    }
  }

  void _onDisconnected(String endpointId) {
    debugPrint('[SharkChat] Disconnected: $endpointId');
    if (_peers.containsKey(endpointId)) {
      _peers[endpointId]!.isConnected = false;
      notifyListeners();
      onStateChangedForWatch?.call();
    }
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type != PayloadType.BYTES) return;
    try {
      final jsonStr = utf8.decode(payload.bytes!);
      final msg = ChatMessage.fromJson(jsonStr, isOwn: false);
      messages.add(msg);
      notifyListeners();
      onStateChangedForWatch?.call();
      debugPrint('[SharkChat] Received from $endpointId: ${msg.text}');
    } catch (e) {
      debugPrint('[SharkChat] Error decoding payload: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _randomSuffix() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  /// Returns the current chat state as JSON for syncing to the WearOS watch.
  String exportStateForWatch() {
    final recentMessages = messages.length > 30
        ? messages.sublist(messages.length - 30)
        : messages;
    return jsonEncode({
      'messages': recentMessages.map((m) => m.toMap()).toList(),
      'peers': discoveredPeers.map((p) => {
        'name': p.name, 
        'id': p.endpointId,
        'isConnected': p.isConnected
      }).toList(),
    });
  }
}
