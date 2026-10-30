import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/study_groups/domain/usecases/study_group_usecase.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_bloc.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_event.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';

class _MockUseCase extends Mock implements StudyGroupUseCase {}

void main() {
  late _MockUseCase useCase;
  late Session session;

  setUp(() {
    useCase = _MockUseCase();
    session = Session()..user = student();
  });

  StudyGroupsBloc build() => StudyGroupsBloc(useCase: useCase, session: session);

  blocTest<StudyGroupsBloc, StudyGroupsState>(
    'loads the student groups',
    build: () {
      when(() => useCase.getStudentGroups(studentId: 'student-1')).thenAnswer((_) async => [group()]);
      return build();
    },
    act: (b) => b.add(const MyGroupsRequested()),
    expect: () => [const StudyGroupsLoading(), MyGroupsLoaded([group()])],
  );

  blocTest<StudyGroupsBloc, StudyGroupsState>(
    'emits a failure state when joining a full group',
    build: () {
      when(() => useCase.joinGroup(groupId: 'g1')).thenThrow(
        const ServerFailure(message: 'Group is full.', code: 'group-full'),
      );
      when(() => useCase.getGroupDetails(groupId: 'g1')).thenAnswer((_) async => group());
      return build();
    },
    act: (b) => b.add(const StudyGroupJoined('g1')),
    expect: () => [
      const StudyGroupActionFailed(message: 'Group is full.', code: 'group-full'),
      const StudyGroupsLoading(),
      GroupDetailsLoaded(group()),
    ],
  );

  blocTest<StudyGroupsBloc, StudyGroupsState>(
    'reports the new group id after creation',
    build: () {
      when(
        () => useCase.createGroup(
          teacherId: any(named: 'teacherId'),
          subject: any(named: 'subject'),
          gradeLevel: any(named: 'gradeLevel'),
          slotId: any(named: 'slotId'),
          notes: any(named: 'notes'),
          capacity: any(named: 'capacity'),
          minStudents: any(named: 'minStudents'),
          maxStudents: any(named: 'maxStudents'),
        ),
      ).thenAnswer((_) async => 'g9');
      return build();
    },
    act: (b) => b.add(
      const StudyGroupCreated(
        teacherId: 't',
        subject: 'Math',
        gradeLevel: 'middle',
        slotId: 's',
        notes: '',
        capacity: 4,
        minStudents: 2,
        maxStudents: 6,
      ),
    ),
    expect: () => [const StudyGroupsLoading(), const StudyGroupActionSucceeded('created', groupId: 'g9')],
  );
}
