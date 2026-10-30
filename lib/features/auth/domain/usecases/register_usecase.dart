import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/auth/domain/repositories/auth_repository.dart';

/// Use case that registers a new user with email and password.
abstract class RegisterUserUseCase {
  Future<void> execute({
    required String email,
    required String password,
    required String name,
    required String role,
  });
}

class RegisterUserUseCaseImpl implements RegisterUserUseCase {
  RegisterUserUseCaseImpl(this.authRepository);

  final AuthRepository authRepository;

  @override
  Future<void> execute({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final errorCode = await authRepository.signUp(
      email: email,
      password: password,
      name: name,
      role: role,
    );
    if (errorCode != null) {
      throw AuthFailure(message: 'Registration failed.', code: errorCode);
    }
  }
}


