import 'package:app_study_share/features/auth/domain/repositories/auth_repository.dart';

/// Use case that signs the current user out.
abstract class LogoutUserUseCase {
  Future<void> execute();
}

class LogoutUserUseCaseImpl implements LogoutUserUseCase {
  LogoutUserUseCaseImpl(this.authRepository);

  final AuthRepository authRepository;

  @override
  Future<void> execute() async {
    await authRepository.signOut();
  }
}


