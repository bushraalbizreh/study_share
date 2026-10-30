import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:app_study_share/features/availability/domain/repositories/availability_repository.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';
import 'package:app_study_share/features/teacher_profile/domain/repositories/teacher_profile_repository.dart';

/// A teacher profile together with the slots students may currently pick.
class TeacherProfileDetails {
  const TeacherProfileDetails({required this.profile, required this.slots});

  final TeacherProfile profile;
  final List<AvailabilitySlot> slots;
}

abstract class GetTeacherProfileUseCase {
  /// Returns null when the teacher has no profile.
  Future<TeacherProfileDetails?> execute(String teacherId);
}

class GetTeacherProfileUseCaseImpl implements GetTeacherProfileUseCase {
  GetTeacherProfileUseCaseImpl(this.profiles, this.availability);

  final TeacherProfileRepository profiles;
  final AvailabilityRepository availability;

  @override
  Future<TeacherProfileDetails?> execute(String teacherId) async {
    final profile = await profiles.getTeacherProfile(teacherId: teacherId);
    if (profile == null) return null;
    final slots = await availability.getAvailableSlots(teacherId: teacherId);
    return TeacherProfileDetails(profile: profile, slots: slots);
  }
}
