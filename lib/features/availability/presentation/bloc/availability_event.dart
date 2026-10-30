import 'package:equatable/equatable.dart';

sealed class AvailabilityEvent extends Equatable {
  const AvailabilityEvent();

  @override
  List<Object?> get props => [];
}

class AvailabilityRequested extends AvailabilityEvent {
  const AvailabilityRequested();
}

class AvailabilitySlotCreated extends AvailabilityEvent {
  const AvailabilitySlotCreated({required this.startAt, required this.durationMinutes});

  final DateTime startAt;
  final int durationMinutes;

  @override
  List<Object?> get props => [startAt, durationMinutes];
}

class AvailabilitySlotDeleted extends AvailabilityEvent {
  const AvailabilitySlotDeleted(this.slotId);

  final String slotId;

  @override
  List<Object?> get props => [slotId];
}
