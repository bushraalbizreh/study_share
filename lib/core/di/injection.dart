import 'package:app_study_share/core/localization/locale_bloc.dart';
import 'package:app_study_share/core/network/api_client.dart';
import 'package:app_study_share/core/network/network_info.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/core/storage/local_store.dart';
import 'package:app_study_share/core/theme/theme_bloc.dart';
import 'package:app_study_share/features/auth/data/datasources/auth_remote_source.dart';
import 'package:app_study_share/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app_study_share/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_study_share/features/auth/domain/usecases/current_user_usecase.dart';
import 'package:app_study_share/features/auth/domain/usecases/login_usecase.dart';
import 'package:app_study_share/features/auth/domain/usecases/logout_usecase.dart';
import 'package:app_study_share/features/auth/domain/usecases/register_usecase.dart';
import 'package:app_study_share/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:app_study_share/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_study_share/features/availability/data/datasources/availability_remote_source.dart';
import 'package:app_study_share/features/availability/data/repositories/availability_repository_impl.dart';
import 'package:app_study_share/features/availability/domain/repositories/availability_repository.dart';
import 'package:app_study_share/features/availability/domain/usecases/availability_usecase.dart';
import 'package:app_study_share/features/availability/presentation/bloc/availability_bloc.dart';
import 'package:app_study_share/features/discovery/data/datasources/discovery_remote_source.dart';
import 'package:app_study_share/features/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:app_study_share/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:app_study_share/features/discovery/domain/usecases/explore_teachers_usecase.dart';
import 'package:app_study_share/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:app_study_share/features/group_chat/data/datasources/group_chat_remote_source.dart';
import 'package:app_study_share/features/group_chat/data/repositories/group_chat_repository_impl.dart';
import 'package:app_study_share/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:app_study_share/features/group_chat/domain/usecases/group_chat_usecase.dart';
import 'package:app_study_share/features/group_chat/presentation/bloc/group_chat_bloc.dart';
import 'package:app_study_share/features/notifications/data/datasources/notifications_remote_source.dart';
import 'package:app_study_share/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:app_study_share/features/notifications/data/services/local_notification_service.dart';
import 'package:app_study_share/features/notifications/data/services/push_notification_service.dart';
import 'package:app_study_share/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:app_study_share/features/notifications/domain/usecases/notifications_usecase.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_study_share/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:app_study_share/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:app_study_share/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:app_study_share/features/profile/data/datasources/profile_remote_source.dart';
import 'package:app_study_share/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:app_study_share/features/profile/domain/repositories/profile_repository.dart';
import 'package:app_study_share/features/profile/domain/usecases/profile_usecase.dart';
import 'package:app_study_share/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:app_study_share/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:app_study_share/features/student_home/domain/usecases/student_home_usecase.dart';
import 'package:app_study_share/features/student_home/presentation/bloc/student_home_bloc.dart';
import 'package:app_study_share/features/study_groups/data/datasources/study_group_remote_source.dart';
import 'package:app_study_share/features/study_groups/data/repositories/study_group_repository_impl.dart';
import 'package:app_study_share/features/study_groups/domain/repositories/study_group_repository.dart';
import 'package:app_study_share/features/study_groups/domain/usecases/study_group_usecase.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_bloc.dart';
import 'package:app_study_share/features/teacher_profile/data/datasources/teacher_profile_remote_source.dart';
import 'package:app_study_share/features/teacher_profile/data/repositories/teacher_profile_repository_impl.dart';
import 'package:app_study_share/features/teacher_profile/domain/repositories/teacher_profile_repository.dart';
import 'package:app_study_share/features/teacher_profile/domain/usecases/get_teacher_profile_usecase.dart';
import 'package:app_study_share/features/teacher_profile/presentation/bloc/teacher_profile_bloc.dart';
import 'package:app_study_share/features/teacher_requests/data/datasources/teacher_requests_remote_source.dart';
import 'package:app_study_share/features/teacher_requests/data/repositories/teacher_requests_repository_impl.dart';
import 'package:app_study_share/features/teacher_requests/domain/repositories/teacher_requests_repository.dart';
import 'package:app_study_share/features/teacher_requests/domain/usecases/teacher_requests_usecase.dart';
import 'package:app_study_share/features/teacher_requests/presentation/bloc/teacher_requests_bloc.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;


Future<void> setupDependencyInjection() async {
  final store = await HiveLocalStore.open();

  getIt
    // Core
    ..registerSingleton<LocalStore>(store)
    ..registerLazySingleton<Session>(Session.new)
    ..registerLazySingleton<NetworkInfo>(NetworkInfoImpl.new)
    ..registerLazySingleton(createApiClient)
    ..registerLazySingleton<ThemeBloc>(() => ThemeBloc(store: getIt()))
    ..registerLazySingleton<LocaleBloc>(() => LocaleBloc(store: getIt()))
    // Auth
    ..registerLazySingleton<AuthRemoteSource>(AuthRemoteSourceImpl.new)
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        getIt(),
        getIt(),
        beforeSignOut: () =>
            getIt<NotificationsRepository>().unregisterDevice(),
      ),
    )
    ..registerLazySingleton<CurrentUserUseCase>(
      () => CurrentUserUseCaseImpl(getIt()),
    )
    ..registerLazySingleton<LoginUserUseCase>(
      () => LoginUserUseCaseImpl(getIt()),
    )
    ..registerLazySingleton<RegisterUserUseCase>(
      () => RegisterUserUseCaseImpl(getIt()),
    )
    ..registerLazySingleton<LogoutUserUseCase>(
      () => LogoutUserUseCaseImpl(getIt()),
    )
    ..registerLazySingleton<ResetPasswordUserUseCase>(
      () => ResetPasswordUserUseCaseImpl(getIt()),
    )
    ..registerFactory<AuthBloc>(
      () => AuthBloc(
        currentUserUseCase: getIt(),
        loginUserUseCase: getIt(),
        registerUserUseCase: getIt(),
        logoutUserUseCase: getIt(),
        resetPasswordUserUseCase: getIt(),
      ),
    )
    // Onboarding & splash
    ..registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(getIt()),
    )
    ..registerFactory<OnboardingBloc>(
      () => OnboardingBloc(onboardingRepository: getIt()),
    )
    ..registerFactory<SplashBloc>(
      () => SplashBloc(authRepository: getIt(), onboardingRepository: getIt()),
    )
    // Profile
    ..registerLazySingleton<ProfileRemoteSource>(
      () => ProfileRemoteSourceImpl(dio: getIt()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<ProfileUseCase>(() => ProfileUseCaseImpl(getIt()))
    ..registerFactory<ProfileBloc>(
      () => ProfileBloc(useCase: getIt(), session: getIt()),
    )
    // Availability
    ..registerLazySingleton<AvailabilityRemoteSource>(
      AvailabilityRemoteSourceImpl.new,
    )
    ..registerLazySingleton<AvailabilityRepository>(
      () => AvailabilityRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<AvailabilityUseCase>(
      () => AvailabilityUseCaseImpl(getIt()),
    )
    ..registerFactory<AvailabilityBloc>(
      () => AvailabilityBloc(useCase: getIt(), session: getIt()),
    )
    // Teacher profile
    ..registerLazySingleton<TeacherProfileRemoteSource>(
      TeacherProfileRemoteSourceImpl.new,
    )
    ..registerLazySingleton<TeacherProfileRepository>(
      () => TeacherProfileRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<GetTeacherProfileUseCase>(
      () => GetTeacherProfileUseCaseImpl(getIt(), getIt()),
    )
    ..registerFactory<TeacherProfileBloc>(
      () => TeacherProfileBloc(useCase: getIt()),
    )
    // Study groups
    ..registerLazySingleton<StudyGroupRemoteSource>(
      StudyGroupRemoteSourceImpl.new,
    )
    ..registerLazySingleton<StudyGroupRepository>(
      () => StudyGroupRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<StudyGroupUseCase>(
      () => StudyGroupUseCaseImpl(getIt()),
    )
    ..registerFactory<StudyGroupsBloc>(
      () => StudyGroupsBloc(useCase: getIt(), session: getIt()),
    )
    // Discovery
    ..registerLazySingleton<DiscoveryRemoteSource>(
      DiscoveryRemoteSourceImpl.new,
    )
    ..registerLazySingleton<DiscoveryRepository>(
      () => DiscoveryRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<ExploreUseCase>(() => ExploreUseCaseImpl(getIt()))
    ..registerFactory<DiscoveryBloc>(() => DiscoveryBloc(useCase: getIt()))
    // Student home
    ..registerLazySingleton<StudentHomeUseCase>(
      () => StudentHomeUseCaseImpl(getIt(), getIt()),
    )
    ..registerFactory<StudentHomeBloc>(
      () => StudentHomeBloc(useCase: getIt(), session: getIt()),
    )
    // Teacher requests
    ..registerLazySingleton<TeacherRequestsRemoteSource>(
      TeacherRequestsRemoteSourceImpl.new,
    )
    
    ..registerLazySingleton<TeacherRequestsRepository>(
      () => TeacherRequestsRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<TeacherRequestsUseCase>(
      () => TeacherRequestsUseCaseImpl(getIt()),
    )
    ..registerFactory<TeacherRequestsBloc>(
      () => TeacherRequestsBloc(useCase: getIt(), session: getIt()),
    )
    /// Notifications
..registerLazySingleton<NotificationsRemoteSource>(
  NotificationsRemoteSourceImpl.new,
)
..registerLazySingleton<NotificationsRepository>(
  () => NotificationsRepositoryImpl(getIt()),
)
..registerLazySingleton<NotificationsUseCase>(
  () => NotificationsUseCaseImpl(getIt()),
)
..registerLazySingleton<NotificationsBloc>(
  () => NotificationsBloc(useCase: getIt()),
)
..registerLazySingleton<LocalNotificationService>(
  LocalNotificationService.new,
)
..registerLazySingleton<PushNotificationService>(
  () => PushNotificationService(
    localNotifications: getIt(),
    notificationsRemoteSource: getIt(),
    notificationsBloc: getIt(),
  ),
)
    // Group chat
    ..registerLazySingleton<GroupChatRemoteSource>(
      GroupChatRemoteSourceImpl.new,
    )
    ..registerLazySingleton<GroupChatRepository>(
      () => GroupChatRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<GroupChatUseCase>(
      () => GroupChatUseCaseImpl(getIt()),
    )
    ..registerFactory<GroupChatBloc>(
      () => GroupChatBloc(useCase: getIt(), session: getIt()),
    );
}
