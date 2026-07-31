import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../appointment/booking_models.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerId =
        ref.watch(authControllerProvider).asData?.value?.customerId;
    final notifications = customerId == null
        ? null
        : ref.watch(notificationsProvider(customerId));

    return Scaffold(
      body: SafeArea(
        child: GlowResponsivePage(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
          child: customerId == null
              ? GlowError(
                  message: 'Bildirimleri görmek için giriş yapmalısın.',
                  onRetry: () => AppNavigation.go(context, AppRoutes.login),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationsProvider(customerId));
                    ref.invalidate(unreadNotificationsProvider(customerId));
                  },
                  child: notifications!.when(
                    loading: () =>
                        const GlowLoading(message: 'Bildirimler yükleniyor'),
                    error: (error, _) => GlowError(
                      message: bookingErrorMessage(error) ?? '$error',
                      onRetry: () =>
                          ref.invalidate(notificationsProvider(customerId)),
                    ),
                    data: (items) => ListView(
                      children: [
                        GlowPageTop(
                          title: 'Bildirimler',
                          subtitle:
                              'Randevu güncellemeleri ve sistem mesajların.',
                          action: GlowIconButton(
                            icon: Icons.refresh,
                            tooltip: 'Yenile',
                            onPressed: () => ref
                                .invalidate(notificationsProvider(customerId)),
                          ),
                        ),
                        if (items.isEmpty)
                          const GlowEmptyState(title: 'Yeni bildirimin yok')
                        else
                          for (final notification in items) ...[
                            _NotificationCard(
                              notification: notification,
                              onMarkRead: notification['read'] == true
                                  ? null
                                  : () => _markRead(
                                        context,
                                        ref,
                                        customerId,
                                        notification,
                                      ),
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: GlowBottomNavigationBar(
        currentIndex: 3,
        onTap: (index) => AppNavigation.goBottomTab(context, index),
      ),
    );
  }

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    int customerId,
    Map<String, dynamic> notification,
  ) async {
    final id = _intValue(notification['notificationId']);
    if (id == null) return;
    try {
      await ref.read(glowBackendServiceProvider).markNotificationAsRead(id);
      ref.invalidate(notificationsProvider(customerId));
      ref.invalidate(unreadNotificationsProvider(customerId));
      if (context.mounted) {
        GlowSnackBar.showSuccess(
            context, 'Bildirim okundu olarak işaretlendi.');
      }
    } catch (error) {
      if (context.mounted) {
        GlowSnackBar.showError(context, bookingErrorMessage(error) ?? '$error');
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, this.onMarkRead});

  final Map<String, dynamic> notification;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final read = notification['read'] == true;
    return GlowCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: read ? AppColors.white : AppColors.roseTint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowMark(
            icon: read
                ? Icons.notifications_none
                : Icons.notifications_active_outlined,
            size: 38,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title']?.toString() ?? 'Bildirim',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  notification['message']?.toString() ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 7),
                Text(
                  notification['createdAt']?.toString() ?? '',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (onMarkRead != null) ...[
                  const SizedBox(height: 8),
                  GlowButton(
                    label: 'Okundu Yap',
                    icon: Icons.done,
                    variant: GlowButtonVariant.secondary,
                    onPressed: onMarkRead,
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

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
