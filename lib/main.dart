
import 'package:app_study_share/app.dart';
import 'package:app_study_share/core/config/supabase_config.dart';
import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/features/notifications/data/services/fcm_background_handler.dart';
import 'package:app_study_share/features/notifications/data/services/push_notification_service.dart';
import 'package:app_study_share/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

await Supabase.initialize(
  url: SupabaseConfig.url,
  publishableKey: SupabaseConfig.publishableKey,
);

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await setupDependencyInjection();

  await getIt<PushNotificationService>().initialize();

  runApp(StudyShareApp());
}
