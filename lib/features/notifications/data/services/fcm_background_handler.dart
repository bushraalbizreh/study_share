
import 'package:app_study_share/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    '[FCM][BACKGROUND] Message ID: ${message.messageId}',
  );

  debugPrint(
    '[FCM][BACKGROUND] Data: ${message.data}',
  );
}
