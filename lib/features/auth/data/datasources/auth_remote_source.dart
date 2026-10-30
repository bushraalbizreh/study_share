import 'package:app_study_share/features/auth/domain/entities/user.dart'as entity;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication + Firestore (`users/{uid}`) data source.
abstract class AuthRemoteSource {
  Future<entity.User?> getCurrentUser();

  /// Each of these returns a Firebase error code, or null on success.
  Future<String?> signIn({required String email, required String password});

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  });

  Future<void> signOut();

  Future<String?> resetPassword({required String email});
}

class AuthRemoteSourceImpl implements AuthRemoteSource {
  AuthRemoteSourceImpl({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  @override
  Future<entity.User?> getCurrentUser() async {
    final fbUser = auth.currentUser;
    if (fbUser == null) return null;
    final snap = await firestore.collection('users').doc(fbUser.uid).get();
    final data = snap.data() ?? const <String, dynamic>{};
    return entity.User(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      name: (data['name'] as String?) ?? fbUser.displayName ?? '',
      role: data['role'] == 'teacher' ? 'teacher' : 'student',
      imageUrl: data['imageUrl'] as String?,
    );
  }

  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    }
  }

  @override
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;
      try {
        // Security Rules only allow creating this document for the caller's own
        // uid, with role student/teacher, and forbid changing it afterwards.
        await firestore.collection('users').doc(fbUser.uid).set({
          'uid': fbUser.uid,
          'name': name,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await fbUser.updateDisplayName(name);
      } on FirebaseException {
        await fbUser.delete();
        return 'profile-save-failed';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    }
  }

  @override
  Future<void> signOut() => auth.signOut();

  @override
  Future<String?> resetPassword({required String email}) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    }
  }
}
