
import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/features/study_groups/data/models/study_group_model.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class StudyGroupRemoteSource {
  Future<List<StudyGroup>> getStudentGroups({
    required String studentId,
  });

  Future<StudyGroup?> getGroupDetails({
    required String groupId,
  });

  Future<String> createGroup(Map<String, dynamic> payload);

  Future<void> joinGroup({required String groupId});

  Future<void> leaveGroup({required String groupId});
}

class StudyGroupRemoteSourceImpl implements StudyGroupRemoteSource {
  StudyGroupRemoteSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _fn = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  @override
  Future<List<StudyGroup>> getStudentGroups({
    required String studentId,
  }) async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;

    print('[MY_GROUPS] Firebase UID: $authUid');
    print('[MY_GROUPS] Session UID: $studentId');

    if (authUid == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'No authenticated Firebase user.',
      );
    }

    final snap = await _db
        .collection(FirestorePaths.groups)
        .where('memberIds', arrayContains: authUid)
        .get();

    print('[MY_GROUPS] Loaded groups: ${snap.docs.length}');

    return snap.docs.map(StudyGroupModel.fromDoc).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  @override
  Future<StudyGroup?> getGroupDetails({
    required String groupId,
  }) async {
    final doc = await _db
        .collection(FirestorePaths.groups)
        .doc(groupId)
        .get();

    return doc.exists ? StudyGroupModel.fromDoc(doc) : null;
  }

  @override
  Future<String> createGroup(Map<String, dynamic> payload) async {
    Never fail(String code, String message) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: code,
        message: message,
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      fail('unauthenticated', 'Please sign in again.');
    }

    final uid = currentUser.uid;

    final teacherValue = payload['teacherId'];
    final slotValue = payload['slotId'];
    final subjectValue = payload['subject'];
    final levelValue = payload['gradeLevel'];
    final capacityValue = payload['capacity'];
    final notes = (payload['notes'] ?? '').toString().trim();

    if (teacherValue is! String || teacherValue.trim().isEmpty) {
      fail('invalid-argument', 'Invalid teacher.');
    }

    if (slotValue is! String || slotValue.trim().isEmpty) {
      fail('invalid-argument', 'Invalid availability slot.');
    }

    if (subjectValue is! String || subjectValue.trim().isEmpty) {
      fail('invalid-argument', 'Invalid subject.');
    }

    if (levelValue is! String ||
        !const ['elementary', 'middle', 'high'].contains(levelValue)) {
      fail('invalid-argument', 'Invalid grade level.');
    }

    if (capacityValue is! int) {
      fail('invalid-argument', 'Invalid group capacity.');
    }

    if (notes.length > 300) {
      fail('invalid-argument', 'Notes cannot exceed 300 characters.');
    }

    final teacherId = teacherValue.trim();
    final slotId = slotValue.trim();
    final subject = subjectValue.trim();
    final gradeLevel = levelValue;
    final capacity = capacityValue;

    final groupRef = _db
        .collection(FirestorePaths.groups)
        .doc();

    final studentRef = _db.collection('users').doc(uid);
    final profileRef = _db.collection('teacherProfiles').doc(teacherId);
    final slotRef = _db.collection('availabilitySlots').doc(slotId);

    await _db.runTransaction<void>((transaction) async {
      // اقرأ جميع المستندات أولًا قبل إجراء أي كتابة.
      final studentSnap = await transaction.get(studentRef);
      final profileSnap = await transaction.get(profileRef);
      final slotSnap = await transaction.get(slotRef);

      if (!studentSnap.exists ||
          studentSnap.data()?['role'] != 'student') {
        fail(
          'permission-denied',
          'Only student accounts can create groups.',
        );
      }

      final profile = profileSnap.data();

      if (!profileSnap.exists || profile == null) {
        fail('not-found', 'Teacher profile not found.');
      }

      if (profile['isComplete'] != true) {
        fail(
          'failed-precondition',
          'The teacher profile is incomplete.',
        );
      }

      final subjects = profile['subjects'];

      if (subjects is! List || !subjects.contains(subject)) {
        fail(
          'invalid-argument',
          'The teacher does not offer this subject.',
        );
      }

      final prices = profile['prices'];

      if (prices is! Map) {
        fail(
          'invalid-argument',
          'Teacher pricing information is missing.',
        );
      }

      final rawPrice = prices[gradeLevel];

      if (rawPrice is! num || rawPrice <= 0) {
        fail(
          'invalid-argument',
          'The teacher does not offer this grade level.',
        );
      }

      final price = rawPrice;

      final rawMin = profile['minStudents'];
      final rawMax = profile['maxStudents'];

      final configuredMin =
          rawMin is num ? rawMin.toInt() : 2;
      final minCapacity =
          configuredMin < 2 ? 2 : configuredMin;

      final maxCapacity =
          rawMax is num ? rawMax.toInt() : 6;

      if (capacity < minCapacity || capacity > maxCapacity) {
        fail(
          'invalid-argument',
          'Capacity is outside the teacher limits.',
        );
      }

      final slot = slotSnap.data();

      if (!slotSnap.exists || slot == null) {
        fail('not-found', 'Availability slot not found.');
      }

      final startAt = slot['startAt'];
      final duration = slot['durationMinutes'];

      if (slot['teacherId'] != teacherId ||
          slot['status'] != 'available' ||
          slot['groupId'] != null ||
          startAt is! Timestamp ||
          duration is! int ||
          !startAt.toDate().isAfter(DateTime.now())) {
        fail(
          'failed-precondition',
          'This availability slot is no longer available.',
        );
      }

      final studentName =
          (studentSnap.data()?['name'] ?? '').toString();

      final teacherName =
          (profile['name'] ?? '').toString();

      // أنشئ المجموعة.
      transaction.set(groupRef, {
        'creatorId': uid,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'slotId': slotId,
        'startAt': startAt,
        'durationMinutes': duration,
        'subject': subject,
        'gradeLevel': gradeLevel,
        'pricePerStudent': price,
        'capacity': capacity,
        'memberIds': [uid],
        'memberNames': {
          uid: studentName,
        },
        'notes': notes,
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // احجز الوقت ضمن المعاملة نفسها.
      transaction.update(slotRef, {
        'status': 'booked',
        'groupId': groupRef.id,
      });
    });

    print('[CREATE_GROUP] Created group: ${groupRef.id}');

    return groupRef.id;
  }

 
@override
Future<void> joinGroup({required String groupId}) async {
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

  final userRef = _db.collection('users').doc(uid);

  // The transaction returns true only when the group is full
  // and the teacher should be notified.
  final shouldNotifyTeacher = await _db.runTransaction<bool>(
    (transaction) async {
      final groupSnap = await transaction.get(groupRef);
      final userSnap = await transaction.get(userRef);

      if (!groupSnap.exists || groupSnap.data() == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Study group not found.',
        );
      }

      if (!userSnap.exists ||
          userSnap.data()?['role'] != 'student') {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Only students can join groups.',
        );
      }

      final group = groupSnap.data()!;

      final rawMembers = group['memberIds'];
      final rawNames = group['memberNames'];
      final rawCapacity = group['capacity'];

      if (rawMembers is! List ||
          rawMembers.any((id) => id is! String) ||
          rawNames is! Map ||
          rawCapacity is! int) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'data-loss',
          message: 'Invalid group data.',
        );
      }

      final members = List<String>.from(rawMembers);
      final memberNames = Map<String, dynamic>.from(rawNames);
      final capacity = rawCapacity;

      // Allow a retry of the notification request if this student
      // already belongs to a full Pending group.
      if (members.contains(uid)) {
        return group['status'] == GroupStatus.pending &&
            members.length >= capacity;
      }

      if (group['status'] != GroupStatus.open) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'This group is no longer open.',
        );
      }

      if (members.length >= capacity) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'This group is full.',
        );
      }

      final studentName =
          (userSnap.data()?['name'] ?? '').toString().trim();

      if (studentName.isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'Student name is missing.',
        );
      }

      final updatedMembers = [...members, uid];
      memberNames[uid] = studentName;

      final becameFull = updatedMembers.length >= capacity;

      final updatedStatus = becameFull
          ? GroupStatus.pending
          : GroupStatus.open;

      transaction.update(groupRef, {
        'memberIds': updatedMembers,
        'memberNames': memberNames,
        'status': updatedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return becameFull;
    },
  );

  // Notify the teacher only after Firestore commits successfully.

debugPrint(
  '[GROUP_JOIN] Group transaction completed. '
  'groupId=$groupId, shouldNotifyTeacher=$shouldNotifyTeacher',
);

if (!shouldNotifyTeacher) {
  debugPrint(
    '[GROUP_JOIN] Notification skipped: group did not become full.',
  );
  return;
}

try {
  debugPrint('[NOTIFICATIONS] Calling notify-group-full...');

  final idToken = await currentUser.getIdToken(true);

  if (idToken == null || idToken.isEmpty) {
    throw StateError('Firebase ID token is missing.');
  }

  final response =
      await Supabase.instance.client.functions.invoke(
    'notify-group-full',
    body: {'groupId': groupId},
    headers: {
      'Authorization': 'Bearer $idToken',
    },
  );

  debugPrint(
    '[NOTIFICATIONS] Function response status: ${response.status}',
  );

  debugPrint(
    '[NOTIFICATIONS] Function response data: ${response.data}',
  );
} catch (error, stackTrace) {
  debugPrint(
    '[NOTIFICATIONS] Function invocation failed: $error',
  );
  debugPrintStack(stackTrace: stackTrace);
}

debugPrint(
  '[GROUP_JOIN] Group transaction completed. '
  'groupId=$groupId, shouldNotifyTeacher=$shouldNotifyTeacher',
);

if (!shouldNotifyTeacher) {
  debugPrint(
    '[GROUP_JOIN] Notification skipped: group did not become full.',
  );
  return;
}

try {
  debugPrint('[NOTIFICATIONS] Calling notify-group-full...');

  final idToken = await currentUser.getIdToken(true);

  if (idToken == null || idToken.isEmpty) {
    throw StateError('Firebase ID token is missing.');
  }

  final response =
      await Supabase.instance.client.functions.invoke(
    'notify-group-full',
    body: {'groupId': groupId},
    headers: {
      'Authorization': 'Bearer $idToken',
    },
  );

  debugPrint(
    '[NOTIFICATIONS] Function response status: ${response.status}',
  );

  debugPrint(
    '[NOTIFICATIONS] Function response data: ${response.data}',
  );
} catch (error, stackTrace) {
  debugPrint(
    '[NOTIFICATIONS] Function invocation failed: $error',
  );
  debugPrintStack(stackTrace: stackTrace);
}


  try {
    final idToken = await currentUser.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw StateError('Firebase ID token is missing.');
    }

    final response = await Supabase.instance.client.functions.invoke(
      'notify-group-full',
      body: {
        'groupId': groupId,
      },
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    debugPrint(
      '[NOTIFICATIONS] Group-full function response: ${response.status}',
    );
  } catch (error, stackTrace) {
    // The group has already been joined successfully.
    // Do not make the student think that joining failed.
    debugPrint(
      '[NOTIFICATIONS] Group-full notification failed: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}



  @override
  Future<void> leaveGroup({
    required String groupId,
  }) async {
    await _fn
        .httpsCallable('leaveStudyGroup')
        .call<Object?>({
      'groupId': groupId,
    });
  }
}
