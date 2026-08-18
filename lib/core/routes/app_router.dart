import 'package:go_router/go_router.dart';
import '../../features/auth/splash_page.dart';
import '../../features/auth/welcome_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/reset_password_page.dart';
import '../../features/home/home_page.dart';
import '../../features/appointment/appointment_page.dart';
import '../../features/appointment/booking_models.dart';
import '../../features/appointment/calendar_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/notification/notification_page.dart';
import '../../features/employee/employee_page.dart';
import '../../features/service/services_page.dart';
import '../../features/service/service_detail_page.dart';
import '../../features/package/packages_page.dart';
import '../../features/package/package_detail_page.dart';
import '../../features/dashboard/customer_dashboard_page.dart';
import '../../features/dashboard/employee_dashboard_page.dart';
import '../../features/dashboard/admin_dashboard_page.dart';
import '../../features/admin/admin_page.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage()),
    GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage()),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginPage(
        initialRole: state.queryParameters['role'],
        guestMode: state.queryParameters['mode'] == 'guest',
      ),
    ),
    GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage()),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (context, state) => ResetPasswordPage(
        token: state.queryParameters['token'],
      ),
    ),
    GoRoute(
        path: AppRoutes.home, builder: (context, state) => const HomePage()),
    GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServicesPage()),
    GoRoute(
      path: AppRoutes.serviceDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['serviceId'] ?? '');
        return ServiceDetailPage(serviceId: id ?? 0);
      },
    ),
    GoRoute(
      path: AppRoutes.packages,
      builder: (context, state) => PackagesPage(
        origin: state.queryParameters['origin'],
      ),
    ),
    GoRoute(
      path: AppRoutes.packageDetail,
      builder: (context, state) {
        final serviceId =
            int.tryParse(state.pathParameters['serviceId'] ?? '') ?? 0;
        final packageId =
            int.tryParse(state.pathParameters['packageId'] ?? '') ?? 0;
        return PackageDetailPage(
          serviceId: serviceId,
          packageId: packageId,
          origin: state.queryParameters['origin'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.appointment,
      // Package selections arrive as query parameters so the wizard can skip
      // asking for a service the customer already chose.
      builder: (context, state) => AppointmentPage(
        packageContext:
            PackageBookingContext.fromQuery(state.queryParameters),
      ),
    ),
    GoRoute(
        path: AppRoutes.calendar,
        builder: (context, state) => const CalendarPage()),
    GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage()),
    GoRoute(
        path: AppRoutes.notification,
        builder: (context, state) => const NotificationPage()),
    GoRoute(
        path: AppRoutes.customerDashboard,
        builder: (context, state) => const CustomerDashboardPage()),
    GoRoute(
        path: AppRoutes.employeeDashboard,
        builder: (context, state) => const EmployeeDashboardPage()),
    GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardPage()),
    GoRoute(
        path: AppRoutes.employee,
        builder: (context, state) => const EmployeePage()),
    GoRoute(
        path: '/admin/legacy', builder: (context, state) => const AdminPage()),
  ],
);
