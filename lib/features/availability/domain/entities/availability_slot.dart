import 'package:equatable/equatable.dart';

/// An individual future lesson slot published by a teacher.
class AvailabilitySlot extends Equatable {
  const AvailabilitySlot({
    required this.id,
    required this.teacherId,
    required this.startAt,
    required this.durationMinutes,
    required this.status,
    this.groupId,
  });

  final String id;
  final String teacherId;
  final DateTime startAt;
  final int durationMinutes;

  /// `available` or `booked`. Only trusted backend code changes this.
  final String status;
  final String? groupId;

  DateTime get endAt => startAt.add(Duration(minutes: durationMinutes));
  bool get isAvailable => status == 'available';

  @override
  List<Object?> get props => [id, teacherId, startAt, durationMinutes, status, groupId];
}
