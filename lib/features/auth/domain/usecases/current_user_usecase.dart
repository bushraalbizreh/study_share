import 'package:app_study_share/features/auth/domain/entities/user.dart';
import 'package:app_study_share/features/auth/domain/repositories/auth_repository.dart';

/// Use case that resolves the currently authenticated user.
abstract class CurrentUserUseCase {
  Future<User?> execute();
}

class CurrentUserUseCaseImpl implements CurrentUserUseCase {
  CurrentUserUseCaseImpl(this.authRepository);

  final AuthRepository authRepository;

  @override
  Future<User?> execute() => authRepository.getCurrentUser();
}


