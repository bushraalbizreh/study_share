
import 'dart:async';

import 'package:app_study_share/features/notifications/data/datasources/notifications_remote_source.dart';
import 'package:app_study_share/features/notifications/data/services/local_notification_service.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService({
    required LocalNotificationService localNotifications,
    required NotificationsRemoteSource notificationsRemoteSource,
    required NotificationsBloc notificationsBloc,
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
  })  : _localNotifications = localNotifications,
        _notificationsRemoteSource = notificationsRemoteSource,
        _notificationsBloc = notificationsBloc,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final LocalNotificationService _localNotifications;
  final NotificationsRemoteSource _notificationsRemoteSource;
  final NotificationsBloc _notificationsBloc;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<User?>? _authSubscription;

  bool _initialized = false;
  bool _hasHandledAuthState = false;
  String? _lastUserId;

  Future<void> initialize() async {
    if (_initialized) return;

    await _localNotifications.initialize(
      onTap: (payload) {
        debugPrint('[NOTIFICATIONS][LOCAL TAP] $payload');
      },
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // Messages received while the app is open.
    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[FCM][FOREGROUND] ${message.messageId}',
      );

      unawaited(
        _localNotifications.showFromRemoteMessage(message).catchError(
          (Object error) {
            debugPrint(
              '[LOCAL NOTIFICATION ERROR] $error',
            );
          },
        ),
      );
    });

    // User taps a notification while the app is in background.
    _openedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM][OPENED] ${message.data}');
    });

    // User launches the app by tapping a notification.
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        '[FCM][INITIAL MESSAGE] ${initialMessage.data}',
      );
    }

    // Start and stop in-app notification stream with auth state.
    _authSubscription = _auth.authStateChanges().listen(
      _handleAuthState,
      onError: (Object error) {
        debugPrint('[FCM][AUTH ERROR] $error');
      },
    );

    _initialized = true;
  }

  void _handleAuthState(User? user) {
    final userId = user?.uid;

    // Avoid processing the same auth state more than once.
    if (_hasHandledAuthState && _lastUserId == userId) {
      return;
    }

    _hasHandledAuthState = true;
    _lastUserId = userId;

    if (user == null) {
      debugPrint('[NOTIFICATIONS] Stopping notification stream.');

      _notificationsBloc.add(
        const NotificationsStopped(),
      );

      return;
    }

    debugPrint(
      '[NOTIFICATIONS] Starting stream for: $userId',
    );

    _notificationsBloc.add(
      NotificationsStarted(userId!),
    );

    // Register device token for the signed-in user.
    unawaited(
      _notificationsRemoteSource.registerDevice().catchError(
        (Object error) {
          debugPrint(
            '[FCM][TOKEN REGISTRATION ERROR] $error',
          );
        },
      ),
    );
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _authSubscription?.cancel();

    _foregroundSubscription = null;
    _openedSubscription = null;
    _authSubscription = null;

    _initialized = false;
    _hasHandledAuthState = false;
    _lastUserId = null;
  }
}
