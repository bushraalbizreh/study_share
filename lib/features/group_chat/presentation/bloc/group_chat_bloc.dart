import 'dart:async';

import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/group_chat/domain/usecases/group_chat_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_study_share/features/group_chat/domain/entities/chat_message.dart';
import 'group_chat_event.dart';
import 'group_chat_state.dart';

class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  GroupChatBloc({required GroupChatUseCase useCase, required Session session})
    : _useCase = useCase,
      _session = session,
      super(const GroupChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessagesUpdated>((e, emit) => emit(GroupChatLoaded(e.messages)));
    on<ChatStreamFailed>(
      (e, emit) => emit(GroupChatError(message: e.message, code: e.code)),
    );
    on<ChatMessageSent>(_onSent);
  }

  final GroupChatUseCase _useCase;
  final Session _session;
  StreamSubscription<dynamic>? _sub;
  String? _groupId;

  Future<void> _onStarted(ChatStarted e, Emitter<GroupChatState> emit) async {
    await _sub?.cancel();
    _groupId = e.groupId;
    emit(const GroupChatLoading());
    _sub = _useCase
        .stream(groupId: e.groupId)
        .listen(
          (m) => add(ChatMessagesUpdated(m)),
          onError: (Object err) {
            final denied = err.toString().contains('permission-denied');
            add(
              ChatStreamFailed(
                message: err.toString(),
                code: denied ? 'chat-unavailable' : null,
              ),
            );
          },
        );
  }

  Future<void> _onSent(ChatMessageSent e, Emitter<GroupChatState> emit) async {
    final user = _session.user;
    final groupId = _groupId;
    if (user == null || groupId == null) return;

    
final List<ChatMessage> before = state is GroupChatLoaded
    ? (state as GroupChatLoaded).messages
    : const <ChatMessage>[];    
    try {
      await _useCase.send(
        groupId: groupId,
        senderId: user.uid,
        senderName: user.name,
        text: e.text,
      );
    } on Failure catch (f) {
      emit(GroupChatSendFailed(before, message: f.message, code: f.code));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
