import 'package:app_study_share/core/error/failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';

/// Runs [action] and maps backend exceptions to [Failure]s.
/// Cloud Functions send a stable code in `details['code']`.
Future<T> guardCall<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Failure {
    rethrow;
  } on FirebaseFunctionsException catch (e) {
    final details = e.details;
    final code = details is Map && details['code'] is String
        ? details['code'] as String
        : e.code;
    throw ServerFailure(message: e.message ?? 'Request failed.', code: code);
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      throw PermissionFailure(
        message: e.message ?? 'Not allowed.',
        code: e.code,
      );
    }
    if (e.code == 'unavailable') {
      throw NetworkFailure(message: e.message ?? 'Offline.', code: e.code);
    }
    throw ServerFailure(message: e.message ?? 'Request failed.', code: e.code);
  } on DioException catch (e) {
    throw NetworkFailure(message: e.message ?? 'Network error.', code: 'network');
  }
}

/// Converts any Firestore value to a [DateTime].
DateTime toDate(Object? value) =>
    value is Timestamp ? value.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
