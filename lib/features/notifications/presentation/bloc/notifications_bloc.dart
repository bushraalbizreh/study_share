import 'dart:async';

import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/notifications/domain/usecases/notifications_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

/// App-level BLoC: provides the live notification list and unread badge.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({required NotificationsUseCase useCase})
    : _useCase = useCase,
      super(const NotificationsInitial()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsStopped>(_onStopped);
    on<NotificationsUpdated>((e, emit) => emit(NotificationsLoaded(e.items)));
    on<NotificationsStreamFailed>(
      (e, emit) => emit(NotificationsError(message: e.message, code: e.code)),
    );
    on<NotificationMarkedRead>(_onMarkRead);
    on<NotificationsAllMarkedRead>(_onMarkAll);
    on<NotificationsAllDeleted>(_onDeleteAll);
  }

  final NotificationsUseCase _useCase;
  StreamSubscription<dynamic>? _sub;
  String? _userId;

  Future<void> _onStarted(NotificationsStarted e, Emitter<NotificationsState> emit) async {
    if (_userId == e.userId && _sub != null) return;
    await _sub?.cancel();
    _userId = e.userId;
    emit(const NotificationsLoading());
    _sub = _useCase
        .watch(userId: e.userId)
        .listen(
          (items) => add(NotificationsUpdated(items)),
          onError: (Object err) {
  debugPrint('[NOTIFICATIONS] STREAM ERROR: $err');

  add(
    NotificationsStreamFailed(
      err.toString(),
      null,
    ),
  );
},
        );
    
  }

  Future<void> _onStopped(NotificationsStopped e, Emitter<NotificationsState> emit) async {
    await _sub?.cancel();
    _sub = null;
    _userId = null;
    emit(const NotificationsInitial());
  }

  Future<void> _onMarkRead(NotificationMarkedRead e, Emitter<NotificationsState> emit) async {
    try {
      await _useCase.markRead(notificationId: e.id);
    } on Failure {
      // The live stream will reflect the real state.
    }
  }

  Future<void> _onMarkAll(
    NotificationsAllMarkedRead e,
    Emitter<NotificationsState> emit,
  ) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _useCase.markAllRead(userId: uid);
    } on Failure {
      // Ignored: stream stays authoritative.
    }
  }

  Future<void> _onDeleteAll(
    NotificationsAllDeleted e,
    Emitter<NotificationsState> emit,
  ) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _useCase.deleteAll(userId: uid);
    } on Failure {
      // Ignored: stream stays authoritative.
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
