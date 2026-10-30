import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/core/utils/formatters.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/group_chat/presentation/bloc/group_chat_bloc.dart';
import 'package:app_study_share/features/group_chat/presentation/bloc/group_chat_event.dart';
import 'package:app_study_share/features/group_chat/presentation/bloc/group_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupChatPage extends StatelessWidget {
  const GroupChatPage({super.key, required this.groupId, this.title});

  final String groupId;
  final String? title;

  @override
  Widget build(BuildContext context) => BlocProvider<GroupChatBloc>(
    create: (_) => getIt<GroupChatBloc>()..add(ChatStarted(groupId)),
    child: _View(title: title ?? context.tr('chat.title')),
  );
}

class _View extends StatefulWidget {
  const _View({required this.title});

  final String title;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<GroupChatBloc>().add(ChatMessageSent(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uid = getIt<Session>().user?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: BlocConsumer<GroupChatBloc, GroupChatState>(
        listenWhen: (_, c) => c is GroupChatSendFailed,
        listener: (context, state) {
          if (state is GroupChatSendFailed) {
            showFeedback(context, context.errorText(state.code, state.message), error: true);
          }
        },
        builder: (context, state) {
          if (state is GroupChatError) {
            return StateView.error(message: context.errorText(state.code, state.message));
          }
          if (state is! GroupChatLoaded) return const StateView.loading();
          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? StateView.empty(
                        icon: Icons.forum_outlined,
                        title: context.tr('chat.empty'),
                        message: context.tr('chat.emptyHint'),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) {
                          final m = state.messages[i];
                          final mine = m.senderId == uid;
                          return Align(
                            alignment: mine
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: mine ? scheme.primary : scheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: mine ? null : Border.all(color: scheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!mine)
                                    Text(
                                      m.senderName,
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  Text(
                                    m.text,
                                    style: TextStyle(color: mine ? scheme.onPrimary : scheme.onSurface),
                                  ),
                                  if (m.createdAt != null)
                                    Text(
                                      Formatters.timeLabel(context, m.createdAt!),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: (mine ? scheme.onPrimary : scheme.onSurfaceVariant)
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(context),
                          decoration: InputDecoration(
                            hintText: context.tr('chat.hint'),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: context.tr('chat.send'),
                        onPressed: () => _send(context),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
