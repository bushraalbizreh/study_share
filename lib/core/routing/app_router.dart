import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/auth/presentation/pages/choose_role_page.dart';
import 'package:app_study_share/features/auth/presentation/pages/login_page.dart';
import 'package:app_study_share/features/auth/presentation/pages/register_page.dart';
import 'package:app_study_share/features/group_chat/presentation/pages/group_chat_page.dart';
import 'package:app_study_share/features/notifications/presentation/pages/notifications_page.dart';
import 'package:app_study_share/features/onboarding/presentation/pages/onboarding_page_1.dart';
import 'package:app_study_share/features/onboarding/presentation/pages/onboarding_page_2.dart';
import 'package:app_study_share/features/onboarding/presentation/pages/onboarding_page_3.dart';
import 'package:app_study_share/features/splash/presentation/pages/splash_page.dart';
import 'package:app_study_share/features/student_home/presentation/pages/student_home_page.dart';
import 'package:app_study_share/features/study_groups/presentation/pages/create_study_group_page.dart';
import 'package:app_study_share/features/study_groups/presentation/pages/group_details_page.dart';
import 'package:app_study_share/features/teacher_profile/presentation/pages/teacher_profile_page.dart';
import 'package:app_study_share/features/teacher_requests/presentation/pages/request_details_page.dart';
import 'package:app_study_share/features/teacher_requests/presentation/pages/teacher_shell.dart';
import 'package:flutter/material.dart';

class AppRouter {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String initialRoute = RouteNames.splash;

  static const _studentOnly = {RouteNames.studentHome, RouteNames.createGroup};
  static const _teacherOnly = {RouteNames.teacherHome, RouteNames.requestDetails};
  static const _authRequired = {
    RouteNames.studentHome,
    RouteNames.teacherHome,
    RouteNames.teacherProfile,
    RouteNames.createGroup,
    RouteNames.groupDetails,
    RouteNames.requestDetails,
    RouteNames.notifications,
    RouteNames.groupChat,
  };

  Route<dynamic> generateRoute(RouteSettings settings) {
    final name = settings.name ?? RouteNames.splash;
    final session = getIt<Session>();
    final role = session.role;

    if (_authRequired.contains(name) && role == null) {
      return _page(const LoginPage(), RouteNames.login);
    }
    if ((_studentOnly.contains(name) && role != 'student') ||
        (_teacherOnly.contains(name) && role != 'teacher')) {
      return _page(role == null ? const LoginPage() : _homeFor(role), RouteNames.homeFor(role ?? 'student'));
    }

    final args = (settings.arguments as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final Widget page = switch (name) {
      RouteNames.splash => const SplashPage(),
      RouteNames.onboarding => const OnboardingPage1(),
      RouteNames.onboarding2 => const OnboardingPage2(),
      RouteNames.onboarding3 => const OnboardingPage3(),
      RouteNames.chooseRole => const ChooseRolePage(),
      RouteNames.login => const LoginPage(),
      RouteNames.register => RegisterPage(initialRole: args['role'] as String?),
      RouteNames.studentHome => const StudentHomePage(),
      RouteNames.teacherHome => const TeacherShell(),
      RouteNames.teacherProfile => TeacherProfilePage(teacherId: args['teacherId'] as String? ?? ''),
      RouteNames.createGroup => CreateStudyGroupPage(
        teacherId: args['teacherId'] as String? ?? '',
        slotId: args['slotId'] as String?,
      ),
      RouteNames.groupDetails => GroupDetailsPage(groupId: args['groupId'] as String? ?? ''),
      RouteNames.requestDetails => RequestDetailsPage(groupId: args['groupId'] as String? ?? ''),
      RouteNames.notifications => const NotificationsPage(),
      RouteNames.groupChat => GroupChatPage(
        groupId: args['groupId'] as String? ?? '',
        title: args['title'] as String?,
      ),
      _ => const SplashPage(),
    };
    return _page(page, name);
  }

  Widget _homeFor(String role) => role == 'teacher' ? const TeacherShell() : const StudentHomePage();

  MaterialPageRoute<dynamic> _page(Widget page, String name) =>
      MaterialPageRoute<dynamic>(builder: (_) => page, settings: RouteSettings(name: name));
}
