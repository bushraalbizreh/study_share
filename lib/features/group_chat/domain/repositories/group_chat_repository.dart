import 'package:app_study_share/features/group_chat/domain/entities/chat_message.dart';

abstract class GroupChatRepository {
  /// Live messages, newest first. Fails with permission-denied unless the group
  /// is `Accepted` and the caller is its teacher or a member.
  Stream<List<ChatMessage>> watchMessages({required String groupId});

  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
  });
}
