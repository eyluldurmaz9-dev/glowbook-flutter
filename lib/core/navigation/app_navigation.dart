import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';

class AppNavigation {
  AppNavigation._();

  static void go(BuildContext context, String route) {
    context.go(route);
  }

  static void goBottomTab(BuildContext context, int index) {
    if (index < 0 || index >= AppRoutes.bottomNavigationRoutes.length) {
      return;
    }
    context.go(AppRoutes.bottomNavigationRoutes[index]);
  }

  static int bottomIndexForLocation(String location) {
    final index = AppRoutes.bottomNavigationRoutes.indexWhere(
      (route) => location.startsWith(route),
    );
    return index < 0 ? 0 : index;
  }
}
