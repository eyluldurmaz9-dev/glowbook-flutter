import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_shadows.dart';
import '../constants/app_spacing.dart';
import '../navigation/app_navigation.dart';
import '../routes/app_routes.dart';
import '../utils/responsive.dart';
import '../../providers/app_providers.dart';

enum GlowButtonVariant { primary, secondary, outlined, text }

class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlowButtonVariant.primary,
    this.fullWidth = false,
    this.loading = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlowButtonVariant variant;
  final bool fullWidth;
  final bool loading;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child =
        _GlowButtonContent(label: label, icon: icon, loading: loading);
    final minimumSize = Size(
      fullWidth ? double.infinity : AppSpacing.touchTarget,
      AppSpacing.touchTarget,
    );

    Widget button;
    switch (variant) {
      case GlowButtonVariant.primary:
        button = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: enabled ? AppShadows.primaryButton : const [],
          ),
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(minimumSize: minimumSize),
            child: child,
          ),
        );
        break;
      case GlowButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.roseTint,
            foregroundColor: AppColors.action,
            minimumSize: minimumSize,
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: child,
        );
        break;
      case GlowButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(minimumSize: minimumSize),
          child: child,
        );
        break;
      case GlowButtonVariant.text:
        button = TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(minimumSize: minimumSize),
          child: child,
        );
        break;
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Tooltip(
        message: tooltip ?? label,
        child: fullWidth
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}

class _GlowButtonContent extends StatelessWidget {
  const _GlowButtonContent({
    required this.label,
    this.icon,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class GlowTextField extends StatefulWidget {
  const GlowTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.enabled = true,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final IconData? prefixIcon;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final Iterable<String>? autofillHints;

  @override
  State<GlowTextField> createState() => _GlowTextFieldState();
}

class _GlowTextFieldState extends State<GlowTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscureText;
    return Semantics(
      textField: true,
      label: widget.label,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        enabled: widget.enabled,
        autofillHints: widget.autofillHints,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          prefixIcon:
              widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
          suffixIcon: isPassword
              ? IconButton(
                  tooltip: _obscured ? 'Şifreyi göster' : 'Şifreyi gizle',
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class GlowPasswordField extends StatelessWidget {
  const GlowPasswordField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return GlowTextField(
      label: label,
      controller: controller,
      focusNode: focusNode,
      obscureText: true,
      prefixIcon: Icons.lock_outline,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: const [AutofillHints.password],
    );
  }
}

class GlowSearchBar extends StatelessWidget {
  const GlowSearchBar({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: hintText,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}

class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.border,
    this.radius = AppRadius.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: AppDurations.normal,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      ),
    );
  }
}

class GlowSectionHeader extends StatelessWidget {
  const GlowSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class GlowDialog {
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Onayla',
    String cancelLabel = 'Vazgeç',
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            GlowButton(
              label: confirmLabel,
              variant: danger
                  ? GlowButtonVariant.outlined
                  : GlowButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showInfo(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}

class GlowSnackBar {
  GlowSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, icon: Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, icon: Icons.error_outline, isError: true);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, icon: Icons.info_outline);
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.primaryText,
        content: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class GlowLoading extends StatelessWidget {
  const GlowLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message ?? 'Yükleniyor',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.action),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(message!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class GlowSkeleton extends StatefulWidget {
  const GlowSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 18,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<GlowSkeleton> createState() => _GlowSkeletonState();
}

class _GlowSkeletonState extends State<GlowSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .45, end: .9).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.petal,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class GlowError extends StatelessWidget {
  const GlowError({
    super.key,
    required this.message,
    this.title = 'Bir şey ters gitti',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GlowMark(icon: Icons.error_outline, size: 46),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              GlowButton(
                label: 'Tekrar dene',
                icon: Icons.refresh,
                onPressed: onRetry!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GlowEmptyState extends StatelessWidget {
  const GlowEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlowMark(icon: icon, size: 46),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              GlowButton(
                label: actionLabel!,
                variant: GlowButtonVariant.secondary,
                onPressed: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GlowAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlowAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBrand = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: showBrand ? const GlowBrand() : Text(title),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class GlowBottomNavigationBar extends ConsumerWidget {
  const GlowBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).asData?.value;
    final signedIn = session?.customerId != null;
    final items = signedIn ? _customerBottomItems : _guestBottomItems;
    final location = GoRouterState.of(context).location;
    final selectedIndex = _bottomIndexForLocation(location, items);

    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppBreakpoints.mobileShell),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  AppNavigation.go(context, items[index].route),
              destinations: [
                for (final item in items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon ?? item.icon),
                    label: item.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _customerBottomItems = [
  GlowNavigationItem(
    label: 'Ana Sayfa',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    route: AppRoutes.home,
  ),
  GlowNavigationItem(
    label: 'Hizmetler',
    icon: Icons.spa_outlined,
    selectedIcon: Icons.spa,
    route: AppRoutes.services,
  ),
  GlowNavigationItem(
    label: 'Randevu',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
    route: AppRoutes.appointment,
  ),
  GlowNavigationItem(
    label: 'Bildirim',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    route: AppRoutes.notification,
  ),
  GlowNavigationItem(
    label: 'Profil',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    route: AppRoutes.profile,
  ),
];

const _guestBottomItems = [
  GlowNavigationItem(
    label: 'Paketler',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    route: AppRoutes.packages,
  ),
  GlowNavigationItem(
    label: 'Randevu',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
    route: AppRoutes.appointment,
  ),
];

int _bottomIndexForLocation(String location, List<GlowNavigationItem> items) {
  final index = items.indexWhere((item) => location.startsWith(item.route));
  return index < 0 ? 0 : index;
}

class GlowWebNavigationRail extends StatelessWidget {
  const GlowWebNavigationRail({
    super.key,
    required this.selectedRoute,
    required this.items,
  });

  final String selectedRoute;
  final List<GlowNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Web navigasyonu',
      child: Container(
        width: AppResponsive.isWide(context) ? 240 : 76,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlowBrand(compact: !AppResponsive.isWide(context)),
            const SizedBox(height: AppSpacing.xxl),
            for (final item in items)
              _GlowNavigationButton(
                item: item,
                selected: selectedRoute == item.route,
                compact: !AppResponsive.isWide(context),
              ),
          ],
        ),
      ),
    );
  }
}

class GlowNavigationItem {
  const GlowNavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String route;
}

class _GlowNavigationButton extends StatelessWidget {
  const _GlowNavigationButton({
    required this.item,
    required this.selected,
    required this.compact,
  });

  final GlowNavigationItem item;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Tooltip(
        message: item.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: () => AppNavigation.go(context, item.route),
          child: Container(
            height: AppSpacing.touchTarget,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? AppColors.roseTint : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: selected ? AppColors.action : AppColors.secondaryText,
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: selected
                                ? AppColors.action
                                : AppColors.primaryText,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlowResponsivePage extends StatelessWidget {
  const GlowResponsivePage({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = AppBreakpoints.content,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final effectiveMaxWidth =
        width < AppBreakpoints.mobile ? AppBreakpoints.mobileShell : maxWidth;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: padding ?? AppResponsive.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}

class GlowBrand extends StatelessWidget {
  const GlowBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'GlowBook',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GlowMark(icon: Icons.auto_awesome),
          if (!compact) ...[
            const SizedBox(width: 10),
            Text(
              'GlowBook',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

class GlowMark extends StatelessWidget {
  const GlowMark({super.key, required this.icon, this.size = 34});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.input),
          topRight: Radius.circular(AppRadius.input),
          bottomRight: Radius.circular(AppRadius.input),
          bottomLeft: Radius.circular(AppRadius.xs),
        ),
      ),
      child: Icon(icon, color: AppColors.action, size: size * .52),
    );
  }
}

class GlowPageTop extends StatelessWidget {
  const GlowPageTop({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 7),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class GlowIconButton extends StatelessWidget {
  const GlowIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      style: IconButton.styleFrom(
        minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        disabledForegroundColor: AppColors.secondaryText,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
    );
  }
}

class GlowEyebrow extends StatelessWidget {
  const GlowEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.action,
            letterSpacing: .9,
          ),
    );
  }
}

class GlowPill extends StatelessWidget {
  const GlowPill({
    super.key,
    required this.label,
    this.color = AppColors.action,
    this.background = AppColors.roseTint,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlowSoftNotice extends StatelessWidget {
  const GlowSoftNotice({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.notifications_outlined,
  });

  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      backgroundColor: AppColors.petal,
      borderColor: AppColors.softBorder,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowMark(icon: icon, size: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(message!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlowStatCard extends StatelessWidget {
  const GlowStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Row(
        children: [
          GlowMark(icon: icon, size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlowServiceCard extends StatelessWidget {
  const GlowServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.price,
    this.duration,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? imageAsset;
  final String? price;
  final String? duration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      radius: AppRadius.serviceTile,
      child: Row(
        children: [
          GlowCatalogImage(
            image: imageAsset,
            icon: Icons.spa_outlined,
            semanticLabel: title,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (price != null || duration != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (price != null) GlowPill(label: price!),
                      if (duration != null)
                        GlowPill(
                          label: duration!,
                          color: AppColors.secondaryText,
                          background: AppColors.petal,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.secondaryText),
        ],
      ),
    );
  }
}

class GlowPackageCard extends StatelessWidget {
  const GlowPackageCard({
    super.key,
    required this.title,
    required this.description,
    this.price,
    this.sessions,
    this.premium = false,
    this.onTap,
  });

  final String title;
  final String description;
  final String? price;
  final String? sessions;
  final bool premium;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      borderColor: premium ? AppColors.goldAccent : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlowMark(
                icon: premium ? Icons.workspace_premium : Icons.inventory_2,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (premium)
                const GlowPill(
                  label: 'Premium',
                  color: AppColors.goldText,
                  background: AppColors.goldTint,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          if (price != null || sessions != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (price != null) GlowPill(label: price!),
                if (sessions != null)
                  GlowPill(
                    label: sessions!,
                    color: AppColors.secondaryText,
                    background: AppColors.petal,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class GlowAppointmentCard extends StatelessWidget {
  const GlowAppointmentCard({
    super.key,
    required this.title,
    required this.time,
    this.subtitle,
    this.status,
    this.onTap,
  });

  final String title;
  final String time;
  final String? subtitle;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      child: Row(
        children: [
          const GlowMark(icon: Icons.calendar_today_outlined, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.action,
                    ),
              ),
              if (status != null) ...[
                const SizedBox(height: AppSpacing.xs),
                GlowPill(
                  label: status!,
                  color: AppColors.successDesign,
                  background: AppColors.greenTint,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class GlowEmployeeCard extends StatelessWidget {
  const GlowEmployeeCard({
    super.key,
    required this.name,
    required this.role,
    this.imageAsset,
    this.rating,
    this.onTap,
  });

  final String name;
  final String role;
  final String? imageAsset;
  final String? rating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      child: Row(
        children: [
          GlowAvatar(name: name, imageAsset: imageAsset),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(role, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (rating != null)
            GlowPill(
              label: rating!,
              icon: Icons.star,
              color: AppColors.goldText,
              background: AppColors.goldTint,
            ),
        ],
      ),
    );
  }
}

class GlowNotificationTile extends StatelessWidget {
  const GlowNotificationTile({
    super.key,
    required this.title,
    required this.message,
    this.time,
    this.unread = false,
    this.onTap,
  });

  final String title;
  final String message;
  final String? time;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      backgroundColor: unread ? AppColors.petal : AppColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowMark(
            icon: unread
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
                if (time != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    time!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.action,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlowAvatar extends StatelessWidget {
  const GlowAvatar({
    super.key,
    required this.name,
    this.imageAsset,
    this.size = 48,
  });

  final String name;
  final String? imageAsset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Semantics(
      image: true,
      label: name,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.blush,
        backgroundImage: imageAsset == null ? null : AssetImage(imageAsset!),
        child: imageAsset == null
            ? Text(
                initial,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.action,
                    ),
              )
            : null,
      ),
    );
  }
}

class GlowAssetThumb extends StatelessWidget {
  const GlowAssetThumb({
    super.key,
    this.imageAsset,
    required this.icon,
    required this.semanticLabel,
    this.size = 74,
  });

  final String? imageAsset;
  final IconData icon;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          width: size,
          height: size,
          color: AppColors.petal,
          child: imageAsset == null
              ? Icon(icon, color: AppColors.action)
              : Image.asset(
                  imageAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(icon, color: AppColors.action);
                  },
                ),
        ),
      ),
    );
  }
}

class GlowCatalogImage extends StatelessWidget {
  const GlowCatalogImage({
    super.key,
    required this.semanticLabel,
    this.image,
    this.icon = Icons.spa_outlined,
    this.height = 92,
    this.width = 92,
    this.radius = 15,
  });

  final String semanticLabel;
  final String? image;
  final IconData icon;
  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final source = image?.trim();
    Widget child;
    if (source == null || source.isEmpty) {
      child = _placeholder();
    } else if (source.startsWith('http://') || source.startsWith('https://')) {
      child = Image.network(
        source,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    } else {
      child = Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: width,
          height: height,
          color: AppColors.petal,
          child: child,
        ),
      ),
    );
  }

  Widget _placeholder() {
    final iconSize = width.isFinite ? width * .36 : 52.0;
    return Icon(icon, color: AppColors.action, size: iconSize.clamp(32, 72));
  }
}

List<GlowNavigationItem> glowDefaultWebNavigationItems = const [
  GlowNavigationItem(
    label: 'Ana Sayfa',
    icon: Icons.home_outlined,
    route: AppRoutes.home,
  ),
  GlowNavigationItem(
    label: 'Hizmetler',
    icon: Icons.spa_outlined,
    route: AppRoutes.services,
  ),
  GlowNavigationItem(
    label: 'Randevular',
    icon: Icons.calendar_today_outlined,
    route: AppRoutes.appointment,
  ),
  GlowNavigationItem(
    label: 'Bildirimler',
    icon: Icons.notifications_outlined,
    route: AppRoutes.notification,
  ),
  GlowNavigationItem(
    label: 'Profil',
    icon: Icons.person_outline,
    route: AppRoutes.profile,
  ),
];
