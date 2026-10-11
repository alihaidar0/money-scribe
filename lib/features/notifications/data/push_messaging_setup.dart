import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:money_scribe/features/notifications/data/firebase_push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/data/unavailable_push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';

/// Starts Firebase for push notifications and returns the repository to use.
///
/// Firebase is configured for Android only so far (the `google-services.json`
/// of the flavor); every other platform, and a build whose configuration
/// cannot be read, gets a repository that reports push as unavailable, so the
/// app still starts.
Future<PushMessagingRepository> createPushMessagingRepository() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const UnavailablePushMessagingRepository();
  }
  try {
    await Firebase.initializeApp();
    return FirebasePushMessagingRepository(FirebaseMessaging.instance);
  } on Exception catch (error) {
    debugPrint('Push notifications are unavailable: ${error.runtimeType}');
    return const UnavailablePushMessagingRepository();
  }
}
