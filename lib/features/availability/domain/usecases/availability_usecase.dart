import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:app_study_share/features/availability/domain/repositories/availability_repository.dart';

/// Use cases for managing teacher availability slots.
abstract class AvailabilityUseCase {
  Future<List<AvailabilitySlot>> getTeacherSlots({required String teacherId});

  Future<List<AvailabilitySlot>> getAvailableSlots({required String teacherId});

  Future<void> createSlot({
    required String teacherId,
    required DateTime startAt,
    required int durationMinutes,
  });

  Future<void> deleteSlot({required String slotId});
}

class AvailabilityUseCaseImpl implements AvailabilityUseCase {
  AvailabilityUseCaseImpl(this.repository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AvailabilityRepository repository;
  final DateTime Function() _now;

  @override
  Future<List<AvailabilitySlot>> getTeacherSlots({required String teacherId}) =>
      repository.getTeacherSlots(teacherId: teacherId);

  @override
  Future<List<AvailabilitySlot>> getAvailableSlots({required String teacherId}) =>
      repository.getAvailableSlots(teacherId: teacherId);

  @override
  Future<void> createSlot({
    required String teacherId,
    required DateTime startAt,
    required int durationMinutes,
  }) async {
    if (!startAt.isAfter(_now())) {
      throw const ServerFailure(message: 'Slot must be in the future.', code: 'slot-in-past');
    }
    if (durationMinutes < 15 || durationMinutes > 240) {
      throw const ServerFailure(message: 'Invalid duration.', code: 'invalid-duration');
    }
    final end = startAt.add(Duration(minutes: durationMinutes));
    final existing = await repository.getTeacherSlots(teacherId: teacherId);
    final overlaps = existing.any(
      (s) => startAt.isBefore(s.endAt) && end.isAfter(s.startAt),
    );
    if (overlaps) {
      throw const ServerFailure(message: 'Slot overlaps another slot.', code: 'slot-overlap');
    }
    await repository.createSlot(
      teacherId: teacherId,
      startAt: startAt,
      durationMinutes: durationMinutes,
    );
  }

  @override
  Future<void> deleteSlot({required String slotId}) =>
      repository.deleteSlot(slotId: slotId);
}
