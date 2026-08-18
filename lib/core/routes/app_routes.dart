class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String services = '/services';
  static const String serviceDetail = '/services/:serviceId';
  static const String packages = '/packages';
  static const String packageDetail = '/packages/:serviceId/:packageId';
  static const String appointment = '/appointment';
  static const String calendar = '/calendar';
  static const String notification = '/notification';
  static const String profile = '/profile';
  static const String customerDashboard = '/customer/dashboard';
  static const String employeeDashboard = '/employee/dashboard';
  static const String employee = '/employee';
  static const String admin = '/admin';

  static const List<String> bottomNavigationRoutes = [
    home,
    services,
    appointment,
    notification,
    profile,
  ];
}
