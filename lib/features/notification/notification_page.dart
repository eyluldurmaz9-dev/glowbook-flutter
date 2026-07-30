import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerId =
        ref.watch(authControllerProvider).valueOrNull?.customerId;
    final notifications = customerId == null
        ? null
        : ref.watch(notificationsProvider(customerId));

    return Scaffold(
      body: SafeArea(
        child: GlowResponsivePage(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
          child: customerId == null
              ? const GlowEmptyState(
                  title: 'Oturum gerekli',
                  message: 'Bildirimleri görmek için giriş yapmalısın.',
                  icon: Icons.lock_outline,
                )
              : notifications!.when(
                  loading: () =>
                      const GlowLoading(message: 'Bildirimler yükleniyor'),
                  error: (error, _) => GlowError(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(notificationsProvider(customerId)),
                  ),
                  data: (items) => ListView(
                    children: [
                      GlowPageTop(
                        title: 'Bildirimler',
                        subtitle: 'Randevuların ve fırsatların burada.',
                        action: GlowIconButton(
                          icon: Icons.close,
                          tooltip: 'Temizle',
                          onPressed: () {},
                        ),
                      ),
                      const GlowSoftNotice(
                        title: 'GlowBook’ta her şey kontrolünde',
                        message:
                            'Randevu değişikliklerini ve salon duyurularını kaçırma.',
                      ),
                      const SizedBox(height: 18),
                      if (items.isEmpty)
                        const GlowEmptyState(title: 'Yeni bildirimin yok')
                      else
                        for (final notification in items) ...[
                          GlowCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const GlowMark(
                                  icon: Icons.notifications_outlined,
                                  size: 38,
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification['title']
                                                      ?.toString() ??
                                                  'Bildirim',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                          ),
                                          if (notification['read'] != true)
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        notification['message']?.toString() ??
                                            '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        notification['createdAt']?.toString() ??
                                            '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
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
}
