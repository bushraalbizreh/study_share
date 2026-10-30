import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/auth/data/datasources/auth_remote_source.dart';
import 'package:app_study_share/features/auth/domain/entities/user.dart';
import 'package:app_study_share/features/auth/domain/repositories/auth_repository.dart';

/// Auth repository. Keeps [Session] in sync and lets other features hook the
/// sign-out (e.g. unregistering the push token) without coupling to auth.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remote, this.session, {this.beforeSignOut});

  final AuthRemoteSource remote;
  final Session session;
  final Future<void> Function()? beforeSignOut;

  @override
  Future<User?> getCurrentUser() => guardCall(() async {
    final user = await remote.getCurrentUser();
    session.user = user;
    return user;
  });

  @override
  Future<String?> signIn({required String email, required String password}) =>
      guardCall(() async {
        final code = await remote.signIn(email: email, password: password);
        if (code != null) {
          throw AuthFailure(message: 'Invalid email or password.', code: code);
        }
        return null;
      });

  @override
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) => guardCall(() async {
    final code = await remote.signUp(
      email: email,
      password: password,
      name: name,
      role: role,
    );
    if (code != null) {
      throw AuthFailure(message: 'Registration failed.', code: code);
    }
    return null;
  });

  @override
  Future<void> signOut() async {
    try {
      await beforeSignOut?.call();
    } catch (_) {
      // Token cleanup must never block signing out.
    }
    await remote.signOut();
    session.user = null;
  }

  @override
  Future<String?> resetPassword({required String email}) => guardCall(() async {
    final code = await remote.resetPassword(email: email);
    if (code != null) {
      throw AuthFailure(message: 'Password reset failed.', code: code);
    }
    return null;
  });
}
