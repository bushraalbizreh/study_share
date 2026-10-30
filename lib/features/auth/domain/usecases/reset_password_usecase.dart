import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/auth/domain/repositories/auth_repository.dart';

/// Use case that requests a password reset email.
abstract class ResetPasswordUserUseCase {
  Future<void> execute({required String email});
}

class ResetPasswordUserUseCaseImpl implements ResetPasswordUserUseCase {
  ResetPasswordUserUseCaseImpl(this.authRepository);

  final AuthRepository authRepository;

  @override
  Future<void> execute({required String email}) async {
    final errorCode = await authRepository.resetPassword(email: email);
    if (errorCode != null) {
      throw AuthFailure(message: 'Password reset failed.', code: errorCode);
    }
  }
}


