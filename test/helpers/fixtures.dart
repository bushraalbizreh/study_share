import 'package:app_study_share/features/auth/domain/entities/user.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';

User student([String uid = 'student-1']) =>
    User(uid: uid, email: '$uid@example.com', name: 'Sara', role: 'student');

StudyGroup group({
  String id = 'g1',
  String status = 'Open',
  List<String> members = const ['student-1'],
  int capacity = 4,
  String subject = 'Math',
  String level = 'middle',
}) => StudyGroup(
  id: id,
  creatorId: members.isEmpty ? 'x' : members.first,
  teacherId: 'teacher-1',
  teacherName: 'Khaled',
  slotId: 'slot-1',
  startAt: DateTime(2030, 1, 1, 16),
  durationMinutes: 60,
  subject: subject,
  gradeLevel: level,
  pricePerStudent: 55,
  capacity: capacity,
  memberIds: members,
  memberNames: {for (final m in members) m: m},
  notes: '',
  status: status,
);
