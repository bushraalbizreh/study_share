import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:app_study_share/features/availability/domain/repositories/availability_repository.dart';
import 'package:app_study_share/features/availability/domain/usecases/availability_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AvailabilityRepository {}

void main() {
  late _MockRepo repo;
  late AvailabilityUseCaseImpl useCase;
  final now = DateTime(2030, 1, 1, 12);

  setUp(() {
    repo = _MockRepo();
    useCase = AvailabilityUseCaseImpl(repo, clock: () => now);
    when(() => repo.getTeacherSlots(teacherId: any(named: 'teacherId'))).thenAnswer(
      (_) async => [
        AvailabilitySlot(
          id: 's1',
          teacherId: 't',
          startAt: DateTime(2030, 1, 2, 10),
          durationMinutes: 60,
          status: 'available',
        ),
      ],
    );
    when(
      () => repo.createSlot(
        teacherId: any(named: 'teacherId'),
        startAt: any(named: 'startAt'),
        durationMinutes: any(named: 'durationMinutes'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> create(DateTime at, [int minutes = 60]) =>
      useCase.createSlot(teacherId: 't', startAt: at, durationMinutes: minutes);

  test('rejects slots in the past', () async {
    await expectLater(
      create(DateTime(2029, 12, 31)),
      throwsA(isA<ServerFailure>().having((f) => f.code, 'code', 'slot-in-past')),
    );
  });

  test('rejects invalid durations', () async {
    await expectLater(
      create(DateTime(2030, 1, 3, 10), 5),
      throwsA(isA<ServerFailure>().having((f) => f.code, 'code', 'invalid-duration')),
    );
  });

  test('rejects overlapping slots', () async {
    await expectLater(
      create(DateTime(2030, 1, 2, 10, 30)),
      throwsA(isA<ServerFailure>().having((f) => f.code, 'code', 'slot-overlap')),
    );
    verifyNever(
      () => repo.createSlot(
        teacherId: any(named: 'teacherId'),
        startAt: any(named: 'startAt'),
        durationMinutes: any(named: 'durationMinutes'),
      ),
    );
  });

  test('creates a valid, non-overlapping slot', () async {
    await create(DateTime(2030, 1, 2, 11));
    verify(
      () => repo.createSlot(teacherId: 't', startAt: DateTime(2030, 1, 2, 11), durationMinutes: 60),
    ).called(1);
  });
}
