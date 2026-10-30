import 'package:app_study_share/features/profile/domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<Profile?> getProfile({required String uid});

  /// Saves the editable fields. The role is never writable from the client.
  Future<void> updateProfile({required Profile profile});

  /// Uploads through a Supabase signed upload URL issued by a Cloud Function
  /// and returns the stored image URL.
  Future<String> uploadProfileImage({required String imagePath});

  Future<void> removeProfileImage();
}
