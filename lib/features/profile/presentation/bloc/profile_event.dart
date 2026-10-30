import 'package:app_study_share/features/profile/domain/entities/profile.dart';
import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

class ProfileUpdated extends ProfileEvent {
  const ProfileUpdated({required this.profile});

  final Profile profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileImageSelected extends ProfileEvent {
  const ProfileImageSelected({required this.imagePath});

  final String imagePath;

  @override
  List<Object?> get props => [imagePath];
}

class ProfileImageRemoved extends ProfileEvent {
  const ProfileImageRemoved();
}
