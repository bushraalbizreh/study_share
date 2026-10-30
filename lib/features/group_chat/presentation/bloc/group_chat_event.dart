import 'package:app_study_share/features/group_chat/domain/entities/chat_message.dart';
import 'package:equatable/equatable.dart';

sealed class GroupChatEvent extends Equatable {
  const GroupChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends GroupChatEvent {
  const ChatStarted(this.groupId);

  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

class ChatMessageSent extends GroupChatEvent {
  const ChatMessageSent(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Internal: stream emissions.
class ChatMessagesUpdated extends GroupChatEvent {
  const ChatMessagesUpdated(this.messages);

  final List<ChatMessage> messages;

  @override
  List<Object?> get props => [messages];
}

class ChatStreamFailed extends GroupChatEvent {
  const ChatStreamFailed({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
