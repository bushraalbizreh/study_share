import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/profile/domain/entities/profile.dart';
import 'package:app_study_share/features/profile/domain/repositories/profile_repository.dart';

abstract class ProfileUseCase {
  Future<Profile?> getProfile({required String uid});

  Future<void> updateProfile({required Profile profile});

  Future<String> uploadImage({required String imagePath});

  Future<void> removeImage();
}

class ProfileUseCaseImpl implements ProfileUseCase {
  ProfileUseCaseImpl(this.repository);

  final ProfileRepository repository;

  @override
  Future<Profile?> getProfile({required String uid}) =>
      repository.getProfile(uid: uid);

  @override
  Future<void> updateProfile({required Profile profile}) {
    if (profile.name.trim().length < 2) {
      throw const ServerFailure(message: 'Name is required.', code: 'invalid-name');
    }
    if (profile.isTeacher) {
      final bad = profile.minStudents < 2 ||
          profile.maxStudents < profile.minStudents ||
          profile.maxStudents > 30;
      if (bad) {
        throw const ServerFailure(message: 'Invalid group size range.', code: 'invalid-capacity');
      }
      if (profile.prices.values.any((p) => p < 0 || p > 100000)) {
        throw const ServerFailure(message: 'Invalid price.', code: 'invalid-price');
      }
    }
    return repository.updateProfile(profile: profile);
  }

  @override
  Future<String> uploadImage({required String imagePath}) =>
      repository.uploadProfileImage(imagePath: imagePath);

  @override
  Future<void> removeImage() => repository.removeProfileImage();
}
