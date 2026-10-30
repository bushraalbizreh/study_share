import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;

  /// Null while the server timestamp is still pending (local echo).
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, senderId, senderName, text, createdAt];
}
