import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';

/// Contract for teacher availability slot management.
abstract class AvailabilityRepository {
  /// All of a teacher's future slots (any status), soonest first.
  Future<List<AvailabilitySlot>> getTeacherSlots({required String teacherId});

  /// Future slots that can still be selected by students.
  Future<List<AvailabilitySlot>> getAvailableSlots({required String teacherId});

  Future<void> createSlot({
    required String teacherId,
    required DateTime startAt,
    required int durationMinutes,
  });

  Future<void> updateSlot({
    required String slotId,
    required DateTime startAt,
    required int durationMinutes,
  });

  Future<void> deleteSlot({required String slotId});
}
