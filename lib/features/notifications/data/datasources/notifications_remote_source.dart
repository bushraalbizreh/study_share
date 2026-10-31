
import 'dart:async';

import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/features/notifications/data/models/app_notification_model.dart';
import 'package:app_study_share/features/notifications/domain/entities/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

abstract class NotificationsRemoteSource {
  Stream<List<AppNotification>> watchNotifications({
    required String userId,
  });

  Future<void> markRead({required String notificationId});

  Future<void> markAllRead({required String userId});

  Future<void> deleteAll({required String userId});

  Future<void> registerDevice();

  Future<void> unregisterDevice();
}

class NotificationsRemoteSourceImpl implements NotificationsRemoteSource {
  NotificationsRemoteSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;

  StreamSubscription<String>? _refreshSub;
  String? _token;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.notifications);

  @override
  Stream<List<AppNotification>> watchNotifications({
    required String userId,
  }) {
    debugPrint('[NOTIFICATIONS] Listening for UID: $userId');

    // Temporary diagnostic: read the known notification directly.
    unawaited(() async {
      try {
        const notificationId = 'm7PulUUtTzcp0JPQ2XuS';

        final doc = await _col.doc(notificationId).get();

        debugPrint(
          '[NOTIFICATIONS] Direct doc exists: ${doc.exists}',
        );

        debugPrint(
          '[NOTIFICATIONS] Direct doc data: ${doc.data()}',
        );
      } catch (error, stackTrace) {
        debugPrint(
          '[NOTIFICATIONS] Direct doc error: $error',
        );

        debugPrintStack(stackTrace: stackTrace);
      }
    }());

    // Listen to the user's notifications.
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '[NOTIFICATIONS] Documents received: ${snapshot.docs.length}',
          );

          return snapshot.docs
              .map(AppNotificationModel.fromDoc)
              .toList();
        });
  }

  @override
  Future<void> markRead({required String notificationId}) =>
      _col.doc(notificationId).update({'read': true});

  @override
  Future<void> markAllRead({required String userId}) async {
    final unread = await _col
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _db.batch();

    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }

    await batch.commit();
  }

  @override
  Future<void> deleteAll({required String userId}) async {
    while (true) {
      final chunk = await _col
          .where('userId', isEqualTo: userId)
          .limit(450)
          .get();

      if (chunk.docs.isEmpty) return;

      final batch = _db.batch();

      for (final d in chunk.docs) {
        batch.delete(d.reference);
      }

      await batch.commit();
    }
  }

  DocumentReference<Map<String, dynamic>>? _deviceDoc(String token) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return null;

    return _db
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.devices)
        .doc(token);
  }

  Future<void> _store(String token) async {
    if (token.isEmpty) {
      throw StateError('FCM token is empty.');
    }

    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw StateError(
        'Cannot save FCM token: user is not authenticated.',
      );
    }

    final ref = _deviceDoc(token);

    if (ref == null) {
      throw StateError('Device document reference is null.');
    }

    debugPrint('[FCM] Saving token for UID: $uid');

    await ref.set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _token = token;

    debugPrint('[FCM] Token saved successfully.');
  }

  @override
  Future<void> registerDevice() async {
    final uid = _auth.currentUser?.uid;

    debugPrint('[FCM] Registration started.');
    debugPrint('[FCM] Current UID: $uid');
    debugPrint('[FCM] Platform: ${defaultTargetPlatform.name}');

    if (uid == null) {
      debugPrint('[FCM] No authenticated user.');
      return;
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '[FCM] Permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Permission denied by user.');
        return;
      }

      await _refreshSub?.cancel();

      _refreshSub = _messaging.onTokenRefresh.listen(
        (newToken) {
          debugPrint('[FCM] Token refreshed.');

          _store(newToken).catchError(
            (Object error, StackTrace stackTrace) {
              debugPrint('[FCM] Refresh storage failed: $error');
            },
          );
        },
        onError: (Object error) {
          debugPrint('[FCM] Token refresh stream error: $error');
        },
      );

      debugPrint('[FCM] Requesting FCM token...');

      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('[FCM] Firebase returned an empty token.');
        return;
      }

      // Never print the actual token.
      debugPrint(
        '[FCM] Token received. Length: ${token.length}',
      );

      await _store(token);
    } catch (error, stackTrace) {
      debugPrint('[FCM] Registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> unregisterDevice() async {
    await _refreshSub?.cancel();
    _refreshSub = null;

    final token = _token ?? await _messaging.getToken();

    if (token != null) {
      await _deviceDoc(token)?.delete();
      await _messaging.deleteToken();
    }

    _token = null;
  }
}
