/// Route names, kept apart from the router so features can navigate without
/// importing every page.
class RouteNames {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const onboarding2 = '/onboarding/2';
  static const onboarding3 = '/onboarding/3';
  static const chooseRole = '/choose_role';
  static const login = '/login';
  static const register = '/register';
  static const studentHome = '/student_home';
  static const teacherHome = '/teacher_home';
  static const teacherProfile = '/teacher_profile';
  static const createGroup = '/create_group';
  static const groupDetails = '/group_details';
  static const requestDetails = '/request_details';
  static const notifications = '/notifications';
  static const groupChat = '/group_chat';

  static String homeFor(String role) =>
      role == 'teacher' ? teacherHome : studentHome;
}
