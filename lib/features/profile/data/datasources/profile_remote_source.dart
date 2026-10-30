import 'dart:io';

import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/features/profile/data/models/profile_model.dart';
import 'package:app_study_share/features/profile/domain/entities/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// This is a public client key (publishable/anon), NOT the service-role key.
// Get it from Supabase Dashboard -> Project Settings -> API Keys.
const String _supabaseProjectUrl = 'https://bdeskhdechhwxdiuuvkm.supabase.co';
const String _supabasePublishableKey = 'sb_publishable_nlhze63qWwpSJNDcTZPpTg_6EhIqjtw';

abstract class ProfileRemoteSource {
  Future<Profile?> getProfile({required String uid});
  Future<void> updateProfile({required Profile profile});
  Future<String> uploadProfileImage({required String imagePath});
  Future<void> removeProfileImage();
}

/// Profile metadata remains in Firestore. Image binaries and signed upload
/// operations use Supabase Storage + Supabase Edge Functions.
class ProfileRemoteSourceImpl implements ProfileRemoteSource {
  ProfileRemoteSourceImpl({
    required Dio dio,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _dio = dio,
       _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final Dio _dio;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<Map<String, dynamic>> _callSupabaseFunction(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in is required.');
    if (_supabasePublishableKey.startsWith('REPLACE_')) {
      throw StateError('Set the Supabase publishable/anon key in profile_remote_source.dart.');
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) throw StateError('Could not obtain a Firebase ID token.');

    final response = await _dio.post<dynamic>(
      '$_supabaseProjectUrl/functions/v1/$functionName',
      data: body,
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'apikey': _supabasePublishableKey,
        'Content-Type': 'application/json',
      }),
    );
    final data = response.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw StateError('Supabase function returned an unexpected response.');
  }

  @override
  Future<Profile?> getProfile({required String uid}) async {
    final user = await _db.collection(FirestorePaths.users).doc(uid).get();
    if (!user.exists) return null;
    final data = user.data()!;
    Map<String, dynamic>? teacher;
    if (data['role'] == 'teacher') {
      teacher = (await _db.collection(FirestorePaths.teacherProfiles).doc(uid).get()).data();
    }
    return ProfileModel.fromDocs(
      uid: uid,
      email: _auth.currentUser?.email ?? '',
      user: data,
      teacher: teacher,
    );
  }

  @override
  Future<void> updateProfile({required Profile profile}) async {
    final batch = _db.batch();
    batch.update(_db.collection(FirestorePaths.users).doc(profile.uid), {
      'name': profile.name,
    });
    if (profile.isTeacher) {
      batch.set(
        _db.collection(FirestorePaths.teacherProfiles).doc(profile.uid),
        ProfileModel.teacherMap(profile),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  @override
  Future<String> uploadProfileImage({required String imagePath}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in is required.');
    final bytes = await File(imagePath).readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw StateError('The image must be smaller than 5 MB.');
    }

    final lower = imagePath.toLowerCase();
    final contentType = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';

    final uid = user.uid;
    final userRef = _db.collection(FirestorePaths.users).doc(uid);
    final profileSnapshot = await userRef.get();
    if (!profileSnapshot.exists) throw StateError('Your user profile was not found in Firestore.');
    final profileData = profileSnapshot.data() ?? <String, dynamic>{};
    final previousPath = profileData['imagePath'] as String?;
    final isTeacher = profileData['role'] == 'teacher';

    final ticket = await _callSupabaseFunction('create-profile-image-upload', {
      'contentType': contentType,
      'size': bytes.length,
    });
    final signedUrl = ticket['signedUrl'] as String?;
    final path = ticket['path'] as String?;
    if (signedUrl == null || path == null) throw StateError('Supabase did not return an upload URL.');

    await _dio.put<void>(
      signedUrl,
      data: bytes,
      options: Options(headers: {
        Headers.contentTypeHeader: contentType,
        Headers.contentLengthHeader: bytes.length,
      }),
    );

    final done = await _callSupabaseFunction('confirm-profile-image', {'path': path});
    final imageUrl = done['imageUrl'] as String?;
    if (imageUrl == null || imageUrl.isEmpty) throw StateError('Supabase did not return the image URL.');

    // Supabase Edge Functions do not use Firebase Admin. Save the image
    // metadata through the signed-in user's Firestore permissions instead.
    try {
      final batch = _db.batch();
      batch.update(userRef, {
        'imagePath': path,
        'imageUrl': imageUrl,
        'imageUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (isTeacher) {
        batch.set(
          _db.collection(FirestorePaths.teacherProfiles).doc(uid),
          {'imageUrl': imageUrl},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (_) {
      // Avoid leaving a newly uploaded file behind if Firestore metadata fails.
      try {
        await _callSupabaseFunction('delete-profile-image', {'path': path});
      } catch (cleanupError) {
        debugPrint('Could not clean up failed new profile image: $cleanupError');
      }
      rethrow;
    }

    if (previousPath != null && previousPath != path && previousPath.startsWith('$uid/')) {
      try {
        await _callSupabaseFunction('delete-profile-image', {'path': previousPath});
      } catch (error) {
        // The new image is already saved; a failed cleanup only leaves an orphaned old file.
        debugPrint('Could not remove previous profile image: $error');
      }
    }
    return imageUrl;
  }

  @override
  Future<void> removeProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in is required.');
    final uid = user.uid;
    final userRef = _db.collection(FirestorePaths.users).doc(uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) return;
    final data = snapshot.data() ?? <String, dynamic>{};
    final previousPath = data['imagePath'] as String?;
    final isTeacher = data['role'] == 'teacher';

    final batch = _db.batch();
    batch.update(userRef, {
      'imagePath': FieldValue.delete(),
      'imageUrl': FieldValue.delete(),
      'imageUpdatedAt': FieldValue.delete(),
    });
    if (isTeacher) {
      final teacherRef = _db.collection(FirestorePaths.teacherProfiles).doc(uid);
      final teacherSnapshot = await teacherRef.get();
      if (teacherSnapshot.exists) {
        batch.update(teacherRef, {'imageUrl': FieldValue.delete()});
      }
    }
    await batch.commit();

    if (previousPath != null && previousPath.startsWith('$uid/')) {
      try {
        await _callSupabaseFunction('delete-profile-image', {'path': previousPath});
      } catch (error) {
        debugPrint('Profile image reference was removed, but Storage cleanup failed: $error');
      }
    }
  }
}
