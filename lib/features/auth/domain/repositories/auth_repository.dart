import 'package:app_study_share/features/auth/domain/entities/user.dart';

/// Contract for authentication operations.
abstract class AuthRepository {
  Future<User?> getCurrentUser();

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


