import 'package:depitun/core/l10n/app_language.dart';
import 'package:depitun/core/l10n/app_strings.dart';
import 'package:depitun/domain/entities/announcement.dart';
import 'package:depitun/presentation/shared/state/announcements_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppStrings.language = AppLanguage.hy);

  final now = DateTime(2026, 10, 19, 12);
  final old = now.subtract(const Duration(days: 1));
  final armenianOnly = Announcement(
    id: 'hy',
    texts: const {AppLanguage.hy: AnnouncementText(title: 'Բարև')},
    sentAt: old,
  );
  final translated = Announcement(
    id: 'all',
    texts: const {
      AppLanguage.hy: AnnouncementText(title: 'Բարև'),
      AppLanguage.ru: AnnouncementText(title: 'Привет'),
      AppLanguage.en: AnnouncementText(title: 'Hello'),
    },
    sentAt: old,
  );

  test('an Armenian-only announcement is hidden outside Armenian', () {
    final gate = AnnouncementGateState(now: now);

    AppStrings.language = AppLanguage.hy;
    expect(gate.visible([armenianOnly, translated]), [armenianOnly, translated]);

    for (final language in [AppLanguage.ru, AppLanguage.en]) {
      AppStrings.language = language;
      expect(gate.visible([armenianOnly, translated]), [translated]);
    }
  });

  test('the bell ignores an announcement the user cannot read', () {
    AppStrings.language = AppLanguage.ru;
    final gate = AnnouncementGateState(now: now, latest: armenianOnly);
    expect(gate.latestVisible, isNull);
  });
}
