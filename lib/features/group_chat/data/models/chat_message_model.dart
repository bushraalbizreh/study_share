import 'package:app_study_share/features/group_chat/domain/entities/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.text,
    required super.createdAt,
  });

  factory ChatMessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final ts = d['createdAt'];
    return ChatMessageModel(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      senderName: d['senderName'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
