import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/announcement.dart';
import '../shared/state/announcements_provider.dart';
import '../shared/widgets/app_loading.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/gradient_scaffold.dart';

/// History of every broadcast push, newest first. Reached from the bell on
/// Home.
///
/// Opening it marks everything shown as seen, which clears the bell's dot;
/// the entries that were new on arrival keep their dot until the screen is
/// left, so the user can still tell which ones they had missed.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  /// What had been seen before this visit; entries newer than it are new.
  late final DateTime? _seenBefore = ref.read(announcementsSeenProvider);

  @override
  void initState() {
    super.initState();
    // Whatever becomes visible while the screen is open counts as seen —
    // including one the gate releases when its push lands.
    ref.listenManual(announcementsProvider, (_, _) => _markSeen());
    ref.listenManual(announcementGateProvider, (_, _) => _markSeen());
    _markSeen();
  }

  void _markSeen() {
    final list = ref.read(announcementsProvider).value;
    if (list == null) return;
    final visible = ref.read(announcementGateProvider).visible(list);
    if (visible.isEmpty) return;
    ref.read(announcementsSeenProvider.notifier).markSeen(visible.first.sentAt);
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(announcementGateProvider);
    final announcements = ref.watch(announcementsProvider).whenData(gate.visible);

    return GradientScaffold(
      appBar: AppBar(title: Text(AppStrings.announcementsTitle)),
      body: switch (announcements) {
        AsyncData(value: final list) when list.isEmpty => EmptyState(
          icon: Icons.notifications_none_rounded,
          title: AppStrings.announcementsEmpty,
          subtitle: AppStrings.announcementsEmptySubtitle,
        ),
        AsyncData(value: final list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            AppSizes.md,
            AppSizes.screenPadding,
            AppSizes.xxl,
          ),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
          itemBuilder: (context, index) {
            final item = list[index];
            final seen = _seenBefore;
            return _AnnouncementCard(
              announcement: item,
              isNew: seen == null || item.sentAt.isAfter(seen),
            );
          },
        ),
        AsyncError() => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: AppStrings.announcementsError,
          subtitle: AppStrings.announcementsErrorSubtitle,
        ),
        _ => const AppLoading(),
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.isNew});

  final Announcement announcement;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sentAt = announcement.sentAt;
    // Never null here: the gate keeps out announcements with no text in the
    // app's language.
    final text = announcement.textIn(AppStrings.language)!;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isNew) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
              ],
              Expanded(
                child: Text(
                  '${AppDateUtils.formatLong(sentAt)}, '
                  '${AppDateUtils.formatTime(sentAt)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (text.title.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              text.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (text.body.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(text.body, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
