import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/availability/data/datasources/availability_remote_source.dart';
import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:app_study_share/features/availability/domain/repositories/availability_repository.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  AvailabilityRepositoryImpl(this.remote);

  final AvailabilityRemoteSource remote;

  @override
  Future<List<AvailabilitySlot>> getTeacherSlots({required String teacherId}) =>
      guardCall(() => remote.getTeacherSlots(teacherId: teacherId));

  @override
  Future<List<AvailabilitySlot>> getAvailableSlots({required String teacherId}) =>
      guardCall(() => remote.getAvailableSlots(teacherId: teacherId));

  @override
  Future<void> createSlot({
    required String teacherId,
    required DateTime startAt,
    required int durationMinutes,
  }) => guardCall(
    () => remote.createSlot(
      teacherId: teacherId,
      startAt: startAt,
      durationMinutes: durationMinutes,
    ),
  );

  @override
  Future<void> updateSlot({
    required String slotId,
    required DateTime startAt,
    required int durationMinutes,
  }) => guardCall(
    () => remote.updateSlot(
      slotId: slotId,
      startAt: startAt,
      durationMinutes: durationMinutes,
    ),
  );

  @override
  Future<void> deleteSlot({required String slotId}) =>
      guardCall(() => remote.deleteSlot(slotId: slotId));
}
