import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/auth/domain/entities/user.dart';
import 'package:app_study_share/features/profile/domain/entities/profile.dart';
import 'package:app_study_share/features/profile/domain/usecases/profile_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required ProfileUseCase useCase, required Session session})
    : _useCase = useCase,
      _session = session,
      super(const ProfileInitial()) {
    on<ProfileRequested>(_onRequested);
    on<ProfileUpdated>(_onUpdated);
    on<ProfileImageSelected>(_onImage);
    on<ProfileImageRemoved>(_onImageRemoved);
  }

  final ProfileUseCase _useCase;
  final Session _session;

  Profile? get _profile => state is ProfileLoaded ? (state as ProfileLoaded).profile : null;

  void _syncSession(Profile p) {
    final u = _session.user;
    if (u != null) {
      _session.user = User(
        uid: u.uid,
        email: u.email,
        name: p.name,
        role: u.role,
        imageUrl: p.imageUrl,
      );
    }
  }

  Future<void> _onRequested(ProfileRequested e, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final p = await _useCase.getProfile(uid: _session.user?.uid ?? '');
      if (p == null) {
        emit(const ProfileError(message: 'Profile not found.', code: 'profile-missing'));
      } else {
        emit(ProfileLoaded(p));
      }
    } on Failure catch (f) {
      emit(ProfileError(message: f.message, code: f.code));
    }
  }

  Future<void> _onUpdated(ProfileUpdated e, Emitter<ProfileState> emit) async {
    final before = _profile ?? e.profile;
    emit(ProfileLoaded(before, busy: true));
    try {
      await _useCase.updateProfile(profile: e.profile);
      _syncSession(e.profile);
      emit(ProfileActionDone(e.profile, 'saved'));
    } on Failure catch (f) {
      emit(ProfileActionFailed(before, message: f.message, code: f.code));
    }
  }

  Future<void> _onImage(ProfileImageSelected e, Emitter<ProfileState> emit) async {
    final before = _profile;
    if (before == null) return;
    emit(ProfileLoaded(before, busy: true));
    try {
      final url = await _useCase.uploadImage(imagePath: e.imagePath);
      final updated = before.copyWith(imageUrl: url);
      _syncSession(updated);
      emit(ProfileActionDone(updated, 'imageUpdated'));
    } on Failure catch (f) {
      emit(ProfileActionFailed(before, message: f.message, code: f.code));
    }
  }

  Future<void> _onImageRemoved(ProfileImageRemoved e, Emitter<ProfileState> emit) async {
    final before = _profile;
    if (before == null) return;
    emit(ProfileLoaded(before, busy: true));
    try {
      await _useCase.removeImage();
      final updated = Profile(
        uid: before.uid,
        email: before.email,
        name: before.name,
        role: before.role,
        imageUrl: null,
        specialization: before.specialization,
        subjects: before.subjects,
        biography: before.biography,
        prices: before.prices,
        minStudents: before.minStudents,
        maxStudents: before.maxStudents,
      );
      _syncSession(updated);
      emit(ProfileActionDone(updated, 'imageRemoved'));
    } on Failure catch (f) {
      emit(ProfileActionFailed(before, message: f.message, code: f.code));
    }
  }
}
