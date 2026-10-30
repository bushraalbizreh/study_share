import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/features/group_chat/data/models/chat_message_model.dart';
import 'package:app_study_share/features/group_chat/domain/entities/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class GroupChatRemoteSource {
  Stream<List<ChatMessage>> watchMessages({required String groupId});

  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
  });
}

class GroupChatRemoteSourceImpl implements GroupChatRemoteSource {
  GroupChatRemoteSourceImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _messages(String groupId) => _db
      .collection(FirestorePaths.groups)
      .doc(groupId)
      .collection(FirestorePaths.messages);

  @override
  Stream<List<ChatMessage>> watchMessages({required String groupId}) => _messages(groupId)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(ChatMessageModel.fromDoc).toList());

  @override
  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await _messages(groupId).add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
