import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  // Timer that periodically re-asserts the BT adapter name
  // (nearby_connections 4.x overwrites it during advertising)
  Timer? _nameRestoreTimer;
  static const _hidChannel = MethodChannel('com.luis.ducky_android/hid');

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

  // ── Helpers ─────────────────────────────────────────────────────────────────
  /// Nearby Connections sometimes returns endpointName as a base64-encoded
  /// blob (known issue in nearby_connections 4.x on some devices).
  /// This tries to decode it and returns the human-readable name.
  String _decodePeerName(String raw) {
    if (raw.isEmpty) return raw;
    // If it already looks like a normal name (contains spaces, short, etc.) keep it
    if (raw.length < 32 || raw.contains(' ') || raw.contains('@')) return raw;
    try {
      // Try standard base64 decode
      final Uint8List bytes = base64Decode(raw);
      final String decoded = utf8.decode(bytes, allowMalformed: false);
      // Only accept if result is non-empty, shorter, and has printable chars
      if (decoded.isNotEmpty &&
          decoded.length <= raw.length &&
          decoded.codeUnits.every((c) => c >= 32 && c < 127)) {
        return decoded.trim();
      }
    } catch (_) {}
    // Try url-safe base64 (replace - with + and _ with /)
    try {
      final String normalized = raw.replaceAll('-', '+').replaceAll('_', '/');
      final String padded = normalized.padRight(
        (normalized.length + 3) ~/ 4 * 4, '=',
      );
      final Uint8List bytes = base64Decode(padded);
      final String decoded = utf8.decode(bytes, allowMalformed: false);
      if (decoded.isNotEmpty &&
          decoded.length <= raw.length &&
          decoded.codeUnits.every((c) => c >= 32 && c < 127)) {
        return decoded.trim();
      }
    } catch (_) {}
    return raw;
  }

  // ── Adapter name restoration ─────────────────────────────────────────────────
  /// nearby_connections 4.x temporarily changes the BT adapter name during
  /// advertising. We restore it immediately after start and every 8 seconds.
  Future<void> _restoreAdapterName() async {
    try {
      await _hidChannel.invokeMethod('setAdapterName', {'name': _localName});
      debugPrint('[SharkChat] Adapter name restored → $_localName');
    } catch (e) {
      debugPrint('[SharkChat] Could not restore adapter name: $e');
    }
  }

  void _startNameRestoreTimer() {
    _nameRestoreTimer?.cancel();
    _nameRestoreTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isRunning) _restoreAdapterName();
    });
  }

  // ── Start / Stop ────────────────────────────────────────────────────────────
  Future<void> start(String deviceName) async {
    if (_isRunning) return;
    _localName = deviceName;
    _isRunning = true;

    try {
      // Start Android foreground service to keep process alive in background
      // Made non-blocking to prevent immediate failure if the service takes time to bind
      _hidChannel.invokeMethod('startForegroundService').catchError((e) {
        debugPrint('[SharkChat] Foreground service start warning: $e');
      });
      
      await Future.delayed(const Duration(milliseconds: 100));

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

      // Restore adapter name immediately (Nearby may have changed it)
      // and keep it correct with a periodic timer
      await Future.delayed(const Duration(milliseconds: 800));
      await _restoreAdapterName();
      _startNameRestoreTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('[SharkChat] Error starting: $e');
      _isRunning = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    // Cancel name-restore timer first
    _nameRestoreTimer?.cancel();
    _nameRestoreTimer = null;

    if (!_isRunning) return;
    _isRunning = false;

    try {
      await Nearby().stopAdvertising();
    } catch (_) {}
    try {
      await Nearby().stopDiscovery();
    } catch (_) {}
    try {
      await Nearby().stopAllEndpoints();
    } catch (_) {}

    _peers.clear();
    notifyListeners();
    debugPrint('[SharkChat] Stopped.');

    try {
      await _hidChannel.invokeMethod('stopForegroundService');
    } catch (_) {}
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
    final readableName = _decodePeerName(endpointName);
    debugPrint('[SharkChat] Found: $endpointId (raw=$endpointName, decoded=$readableName)');
    if (!_peers.containsKey(endpointId)) {
      _peers[endpointId] = ChatPeer(endpointId: endpointId, name: readableName);
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
    final readableName = _decodePeerName(info.endpointName);
    debugPrint('[SharkChat] Connection initiated with $endpointId ($readableName)');
    // Update peer name from connection info (more reliable than onEndpointFound)
    _peers[endpointId] = ChatPeer(endpointId: endpointId, name: readableName);
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
