
import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/features/study_groups/data/models/study_group_model.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

abstract class TeacherRequestsRemoteSource {
  Future<List<StudyGroup>> getRequests({
    required String teacherId,
  });

  Future<StudyGroup?> getRequest({
    required String groupId,
  });

  Future<void> decide({
    required String groupId,
    required bool accept,
  });
}

class TeacherRequestsRemoteSourceImpl
    implements TeacherRequestsRemoteSource {
  TeacherRequestsRemoteSourceImpl({
    FirebaseFirestore? firestore,
    SupabaseClient? supabase,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _supabase = supabase ?? Supabase.instance.client;

  final FirebaseFirestore _db;
  final SupabaseClient _supabase;

  @override
  Future<List<StudyGroup>> getRequests({
    required String teacherId,
  }) async {
    final snap = await _db
        .collection(FirestorePaths.groups)
        .where('teacherId', isEqualTo: teacherId)
        .where(
          'status',
          whereIn: [
            GroupStatus.pending,
            GroupStatus.accepted,
          ],
        )
        .get();

    return snap.docs.map(StudyGroupModel.fromDoc).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  @override
  Future<StudyGroup?> getRequest({
    required String groupId,
  }) async {
    final doc = await _db
        .collection(FirestorePaths.groups)
        .doc(groupId)
        .get();

    return doc.exists
        ? StudyGroupModel.fromDoc(doc)
        : null;
  }

  @override
  Future<void> decide({
    required String groupId,
    required bool accept,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Please sign in again.',
      );
    }

    final uid = currentUser.uid;

    final groupRef = _db
        .collection(FirestorePaths.groups)
        .doc(groupId);

    // Step 1: Verify the teacher and save the decision.
    await _db.runTransaction<void>((transaction) async {
      final groupSnap = await transaction.get(groupRef);

      if (!groupSnap.exists || groupSnap.data() == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Study group not found.',
        );
      }

      final group = groupSnap.data()!;

      if (group['teacherId'] != uid) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'You are not the teacher of this group.',
        );
      }

      if (group['status'] != GroupStatus.pending) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'This request is no longer pending.',
        );
      }

      transaction.update(groupRef, {
        'status': accept
            ? GroupStatus.accepted
            : GroupStatus.rejected,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // Step 2: Notify students after Firestore commits.
    await _notifyStudents(
      currentUser: currentUser,
      groupId: groupId,
      accept: accept,
    );
  }

  Future<void> _notifyStudents({
    required User currentUser,
    required String groupId,
    required bool accept,
  }) async {
    try {
      debugPrint(
        '[NOTIFICATIONS] Sending group decision: '
        '${accept ? 'accepted' : 'rejected'}',
      );

      // Get a fresh Firebase Authentication ID token.
      final idToken = await currentUser.getIdToken(true);

      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Firebase ID token is missing.',
        );
      }

      // Call the Supabase Edge Function.
      final response = await _supabase.functions.invoke(
        'notify-group-decision',
        body: {
          'groupId': groupId,
          'decision': accept ? 'accepted' : 'rejected',
        },
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      debugPrint(
        '[NOTIFICATIONS] Decision function status: '
        '${response.status}',
      );

      debugPrint(
        '[NOTIFICATIONS] Decision function response: '
        '${response.data}',
      );
    } catch (error, stackTrace) {
      // The teacher's decision has already been saved.
      // A notification failure must not undo that decision.
      debugPrint(
        '[NOTIFICATIONS] Decision notification failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }
}
