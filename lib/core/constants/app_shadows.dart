import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.softShadow,
      blurRadius: 34,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> elevatedCard = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 60,
      offset: Offset(0, 20),
    ),
  ];

  static const List<BoxShadow> primaryButton = [
    BoxShadow(
      color: AppColors.primaryShadow,
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}
