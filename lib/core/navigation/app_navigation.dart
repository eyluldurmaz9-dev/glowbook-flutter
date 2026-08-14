import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';

/// Lives above every routed page (attached to [MaterialApp.scaffoldMessengerKey]),
/// so a SnackBar shown right before navigating away — e.g. a booking success
/// toast — keeps displaying instead of being torn down with the old page's Scaffold.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
