import 'dart:convert';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isOwn;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isOwn,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isOwn': isOwn,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map, {bool isOwn = false}) {
    return ChatMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      text: map['text'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isOwn: isOwn,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ChatMessage.fromJson(String source, {bool isOwn = false}) =>
      ChatMessage.fromMap(jsonDecode(source) as Map<String, dynamic>, isOwn: isOwn);
}

class ChatPeer {
  final String endpointId;
  final String name;
  bool isConnected;

  ChatPeer({
    required this.endpointId,
    required this.name,
    this.isConnected = false,
  });
}
