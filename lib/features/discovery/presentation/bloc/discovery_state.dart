import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';
import 'package:equatable/equatable.dart';

sealed class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => [];
}

class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial();
}

class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading();
}

class DiscoveryLoaded extends DiscoveryState {
  const DiscoveryLoaded({
    required this.allTeachers,
    required this.allGroups,
    this.query = '',
    this.tab = 0,
    this.level,
  });

  final List<TeacherProfile> allTeachers;
  final List<StudyGroup> allGroups;
  final String query;

  /// 0 = teachers, 1 = open groups.
  final int tab;
  final String? level;

  bool _match(String text) => text.toLowerCase().contains(query.trim().toLowerCase());

  List<TeacherProfile> get teachers => allTeachers.where((t) {
    final levelOk = level == null || t.levels.contains(level);
    final textOk = query.trim().isEmpty ||
        _match(t.name) || _match(t.specialization) || t.subjects.any(_match);
    return levelOk && textOk;
  }).toList();

  List<StudyGroup> get groups => allGroups.where((g) {
    final levelOk = level == null || g.gradeLevel == level;
    final textOk = query.trim().isEmpty || _match(g.subject) || _match(g.teacherName);
    return levelOk && textOk;
  }).toList();

  DiscoveryLoaded copyWith({String? query, int? tab, Object? level = _keep}) =>
      DiscoveryLoaded(
        allTeachers: allTeachers,
        allGroups: allGroups,
        query: query ?? this.query,
        tab: tab ?? this.tab,
        level: identical(level, _keep) ? this.level : level as String?,
      );

  static const Object _keep = Object();

  @override
  List<Object?> get props => [allTeachers, allGroups, query, tab, level];
}

class DiscoveryError extends DiscoveryState {
  const DiscoveryError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
