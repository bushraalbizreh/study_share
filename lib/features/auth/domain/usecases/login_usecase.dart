import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/auth/domain/repositories/auth_repository.dart';

/// Use case that signs an existing user in with email and password.
abstract class LoginUserUseCase {
  Future<void> execute({required String email, required String password});
}

class LoginUserUseCaseImpl implements LoginUserUseCase {
  LoginUserUseCaseImpl(this.authRepository);

  final AuthRepository authRepository;

  @override
  Future<void> execute({
    required String email,
    required String password,
  }) async {
    final errorCode = await authRepository.signIn(
      email: email,
      password: password,
    );
    if (errorCode != null) {
      throw AuthFailure(message: 'Invalid email or password.', code: errorCode);
    }
  }
}


