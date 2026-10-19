import 'package:depitun/core/di/providers.dart';
import 'package:depitun/core/l10n/app_language.dart';
import 'package:depitun/core/l10n/app_strings.dart';
import 'package:depitun/core/utils/date_utils.dart';
import 'package:depitun/data/models/app_settings_model.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:depitun/presentation/shared/state/settings_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => AppStrings.language = AppLanguage.hy);

  group('fresh install follows the phone', () {
    test('Armenian only on an Armenian phone', () {
      expect(AppLanguage.fromLocales(const [Locale('hy', 'AM')]),
          AppLanguage.hy);
    });

    test('Russian and English phones never land in Armenian', () {
      expect(AppLanguage.fromLocales(const [Locale('ru', 'RU')]),
          AppLanguage.ru);
      expect(AppLanguage.fromLocales(const [Locale('en', 'US')]),
          AppLanguage.en);
    });

    test('an untranslated language falls back to English', () {
      expect(AppLanguage.fromLocales(const [Locale('de', 'DE')]),
          AppLanguage.en);
      expect(AppLanguage.fromLocales(const []), AppLanguage.en);
    });

    test('the first translated preference wins', () {
      expect(
        AppLanguage.fromLocales(const [Locale('de'), Locale('ru'), Locale('hy')]),
        AppLanguage.ru,
      );
    });
  });

  group('stored choice', () {
    test('round-trips through the settings JSON', () {
      final json = AppSettingsModel(
        AppSettings.defaults.copyWith(language: AppLanguage.ru),
      ).toJson();
      expect(AppSettingsModel.fromJson(json).settings.language, AppLanguage.ru);
    });

    test('settings from the Armenian-only build stay Armenian', () {
      expect(
        AppSettingsModel.fromJson(const {'themeMode': 'dark'}).settings.language,
        AppLanguage.hy,
      );
    });

    test('switching updates the strings, and a reset keeps the language',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSettingsProvider.overrideWithValue(AppSettings.defaults),
        initialActiveIdProvider.overrideWithValue(null),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(settingsControllerProvider.notifier);
      expect(AppStrings.navSettings, 'Կարգավորումներ');

      await notifier.setLanguage(AppLanguage.en);
      expect(AppStrings.navSettings, 'Settings');

      await notifier.resetToDefaults();
      expect(container.read(settingsControllerProvider).language,
          AppLanguage.en);
    });
  });

  test('Russian dates put the month in the genitive', () {
    AppStrings.language = AppLanguage.ru;
    expect(AppDateUtils.formatLong(DateTime(2027, 3, 5)), '5 марта 2027');
    expect(AppDateUtils.formatMonthYear(DateTime(2027, 3, 5)), 'Март 2027');
    AppStrings.language = AppLanguage.en;
    expect(AppDateUtils.formatLong(DateTime(2027, 3, 5)), '5 March 2027');
  });
}
