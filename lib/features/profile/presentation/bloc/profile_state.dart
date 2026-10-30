import 'package:app_study_share/features/profile/domain/entities/profile.dart';
import 'package:equatable/equatable.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile, {this.busy = false});

  final Profile profile;

  /// True while an image upload/removal is running.
  final bool busy;

  @override
  List<Object?> get props => [profile, busy];
}

/// A [ProfileLoaded] with one-time success feedback (`saved`, `imageUpdated`, `imageRemoved`).
class ProfileActionDone extends ProfileLoaded {
  const ProfileActionDone(super.profile, this.action);

  final String action;

  @override
  List<Object?> get props => [profile, busy, action];
}

/// A [ProfileLoaded] with one-time error feedback.
class ProfileActionFailed extends ProfileLoaded {
  const ProfileActionFailed(super.profile, {required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [profile, busy, message, code];
}

class ProfileError extends ProfileState {
  const ProfileError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
