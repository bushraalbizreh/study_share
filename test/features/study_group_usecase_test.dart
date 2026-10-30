import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/study_groups/domain/repositories/study_group_repository.dart';
import 'package:app_study_share/features/study_groups/domain/usecases/study_group_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements StudyGroupRepository {}

void main() {
  late _MockRepo repo;
  late StudyGroupUseCaseImpl useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = StudyGroupUseCaseImpl(repo);
    when(
      () => repo.createGroup(
        teacherId: any(named: 'teacherId'),
        subject: any(named: 'subject'),
        gradeLevel: any(named: 'gradeLevel'),
        slotId: any(named: 'slotId'),
        notes: any(named: 'notes'),
        capacity: any(named: 'capacity'),
      ),
    ).thenAnswer((_) async => 'new-id');
  });

  Future<String> create({int capacity = 4, String subject = 'Math', String slot = 's1'}) =>
      Future.sync(
        () => useCase.createGroup(
          teacherId: 't',
          subject: subject,
          gradeLevel: 'middle',
          slotId: slot,
          notes: ' hi ',
          capacity: capacity,
          minStudents: 2,
          maxStudents: 6,
        ),
      );

  test('rejects capacity outside the teacher range', () async {
    await expectLater(create(capacity: 7), throwsA(isA<ServerFailure>()));
    await expectLater(create(capacity: 1), throwsA(isA<ServerFailure>()));
  });

  test('rejects missing subject or slot', () async {
    await expectLater(create(subject: ' '), throwsA(isA<ServerFailure>()));
    await expectLater(create(slot: ''), throwsA(isA<ServerFailure>()));
  });

  test('creates and trims input', () async {
    expect(await create(), 'new-id');
    verify(
      () => repo.createGroup(
        teacherId: 't',
        subject: 'Math',
        gradeLevel: 'middle',
        slotId: 's1',
        notes: 'hi',
        capacity: 4,
      ),
    ).called(1);
  });
}
