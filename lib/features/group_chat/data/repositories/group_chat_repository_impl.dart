import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/group_chat/data/datasources/group_chat_remote_source.dart';
import 'package:app_study_share/features/group_chat/domain/entities/chat_message.dart';
import 'package:app_study_share/features/group_chat/domain/repositories/group_chat_repository.dart';

class GroupChatRepositoryImpl implements GroupChatRepository {
  GroupChatRepositoryImpl(this.remote);

  final GroupChatRemoteSource remote;

  @override
  Stream<List<ChatMessage>> watchMessages({required String groupId}) =>
      remote.watchMessages(groupId: groupId);

  @override
  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
  }) => guardCall(
    () => remote.sendMessage(
      groupId: groupId,
      senderId: senderId,
      senderName: senderName,
      text: text,
    ),
  );
}
