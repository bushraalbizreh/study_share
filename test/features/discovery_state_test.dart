import 'package:app_study_share/features/discovery/presentation/bloc/discovery_state.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/fixtures.dart' as fixtures;

import '../helpers/fixtures.dart';

void main() {
  const math = TeacherProfile(
    uid: 'a',
    name: 'Khaled',
    specialization: 'Mathematics',
    subjects: ['Algebra'],
    prices: {'high': 70},
    isComplete: true,
  );
  const english = TeacherProfile(
    uid: 'b',
    name: 'Lina',
    specialization: 'English',
    subjects: ['Grammar'],
    prices: {'elementary': 40, 'middle': 45},
    isComplete: true,
  );

  final state = DiscoveryLoaded(
    allTeachers: const [math, english],
    allGroups: [group(subject: 'Physics', level: 'high'), group(id: 'g2', subject: 'Reading', level: 'elementary')],
  );

  test('filters teachers by text across name, specialization and subjects', () {
    expect(state.copyWith(query: 'alg').teachers, [math]);
    expect(state.copyWith(query: 'LINA').teachers, [english]);
  });

  test('filters by stage the teacher actually prices', () {
    expect(state.copyWith(level: 'middle').teachers, [english]);
    expect(state.copyWith(level: 'high').teachers, [math]);
  });

  test('filters groups and can clear the level filter', () {
    final high = state.copyWith(level: 'high');
    expect(high.groups.map((g) => g.subject), ['Physics']);
    expect(high.copyWith(level: null).groups.length, 2);
  });
}
