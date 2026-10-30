import 'package:app_study_share/features/group_chat/domain/entities/chat_message.dart';
import 'package:equatable/equatable.dart';

sealed class GroupChatState extends Equatable {
  const GroupChatState();

  @override
  List<Object?> get props => [];
}

class GroupChatInitial extends GroupChatState {
  const GroupChatInitial();
}

class GroupChatLoading extends GroupChatState {
  const GroupChatLoading();
}

class GroupChatLoaded extends GroupChatState {
  const GroupChatLoaded(this.messages);

  /// Newest first.
  final List<ChatMessage> messages;

  @override
  List<Object?> get props => [messages];
}

/// A [GroupChatLoaded] carrying a one-time send error.
class GroupChatSendFailed extends GroupChatLoaded {
  const GroupChatSendFailed(super.messages, {required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [messages, message, code];
}

/// Chat unavailable (not Accepted, or the caller is not a participant).
class GroupChatError extends GroupChatState {
  const GroupChatError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
