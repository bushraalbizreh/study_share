import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/group_chat/domain/entities/chat_message.dart';
import 'package:app_study_share/features/group_chat/domain/repositories/group_chat_repository.dart';

abstract class GroupChatUseCase {
  Stream<List<ChatMessage>> stream({required String groupId});

  Future<void> send({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
  });
}

class GroupChatUseCaseImpl implements GroupChatUseCase {
  GroupChatUseCaseImpl(this.repository);

  static const maxLength = 2000;
  final GroupChatRepository repository;

  @override
  Stream<List<ChatMessage>> stream({required String groupId}) =>
      repository.watchMessages(groupId: groupId);

  @override
  Future<void> send({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > maxLength) {
      throw const ServerFailure(message: 'Invalid message.', code: 'invalid-message');
    }
    return repository.sendMessage(
      groupId: groupId,
      senderId: senderId,
      senderName: senderName,
      text: trimmed,
    );
  }
}
