import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:equatable/equatable.dart';

sealed class AvailabilityState extends Equatable {
  const AvailabilityState();

  @override
  List<Object?> get props => [];
}

class AvailabilityInitial extends AvailabilityState {
  const AvailabilityInitial();
}

class AvailabilityLoading extends AvailabilityState {
  const AvailabilityLoading();
}

class AvailabilityLoaded extends AvailabilityState {
  const AvailabilityLoaded(this.slots);

  final List<AvailabilitySlot> slots;

  @override
  List<Object?> get props => [slots];
}

/// A [AvailabilityLoaded] carrying one-time success feedback (`created`, `deleted`).
class AvailabilityActionDone extends AvailabilityLoaded {
  const AvailabilityActionDone(super.slots, this.action);

  final String action;

  @override
  List<Object?> get props => [slots, action];
}

/// A [AvailabilityLoaded] carrying one-time error feedback.
class AvailabilityActionFailed extends AvailabilityLoaded {
  const AvailabilityActionFailed(super.slots, {required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [slots, message, code];
}

class AvailabilityError extends AvailabilityState {
  const AvailabilityError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
