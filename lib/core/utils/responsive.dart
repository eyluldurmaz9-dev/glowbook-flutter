import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

class AppResponsive {
  AppResponsive._();

  static bool isMobile(BuildContext context) {
    return widthOf(context) < AppBreakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = widthOf(context);
    return width >= AppBreakpoints.mobile && width < AppBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return widthOf(context) >= AppBreakpoints.tablet;
  }

  static bool isWide(BuildContext context) {
    return widthOf(context) >= AppBreakpoints.desktop;
  }

  static double widthOf(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double maxContentWidth(BuildContext context) {
    final width = widthOf(context);
    if (width >= AppBreakpoints.wide) return 1200;
    if (width >= AppBreakpoints.tablet) return AppBreakpoints.content;
    if (width < AppBreakpoints.mobile) return AppBreakpoints.mobileShell;
    return width;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageDesktopX,
        vertical: AppSpacing.xxxl,
      );
    }
    return const EdgeInsets.fromLTRB(
      AppSpacing.pageMobileX,
      AppSpacing.pageMobileTop,
      AppSpacing.pageMobileX,
      AppSpacing.xxl,
    );
  }

  static int gridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static Widget buildLayout({
    required BuildContext context,
    required Widget child,
    double? horizontalPadding,
  }) {
    final padding = horizontalPadding == null
        ? pagePadding(context)
        : EdgeInsets.symmetric(horizontal: horizontalPadding);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
