import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/profile/data/datasources/profile_remote_source.dart';
import 'package:app_study_share/features/profile/domain/entities/profile.dart';
import 'package:app_study_share/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this.remote);

  final ProfileRemoteSource remote;

  @override
  Future<Profile?> getProfile({required String uid}) =>
      guardCall(() => remote.getProfile(uid: uid));

  @override
  Future<void> updateProfile({required Profile profile}) =>
      guardCall(() => remote.updateProfile(profile: profile));

  @override
  Future<String> uploadProfileImage({required String imagePath}) =>
      guardCall(() => remote.uploadProfileImage(imagePath: imagePath));

  @override
  Future<void> removeProfileImage() => guardCall(remote.removeProfileImage);
}
