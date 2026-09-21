import 'dart:convert';

import 'package:depitun/data/models/app_settings_model.dart';
import 'package:depitun/data/models/soldier_profile_model.dart';
import 'package:depitun/domain/entities/app_settings.dart';
import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SoldierProfile survives a JSON round-trip', () {
    final original = SoldierProfile(
      id: 'abc',
      name: 'Արամ',
      unit: 'Ն զորամաս',
      serviceStart: DateTime(2025, 3, 15, 8, 30),
      serviceDurationDays: 730,
      photoPath: '/data/photo.jpg',
      createdAt: DateTime(2025, 3, 15, 9),
    );

    final json = jsonEncode(SoldierProfileModel.fromEntity(original).toJson());
    final restored = SoldierProfileModel.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    ).toEntity();

    expect(restored, original);
    expect(restored.dischargeDate, original.dischargeDate);
  });

  test('AppSettings survives a JSON round-trip', () {
    const original = AppSettings(
      themeMode: AppThemeMode.dark,
      accentColorId: 'blue',
      fontScaleId: 'large',
      animationLevel: AnimationLevel.reduced,
      backgroundImagePath: '/data/bg.jpg',
      notificationsEnabled: true,
      dailyReminderEnabled: true,
      dailyReminderMinutes: 8 * 60 + 15,
      milestoneNotificationsEnabled: false,
      unlockedMilestones: {
        's1': {'pct25', 'pct50'},
        's2': {'day100'},
      },
    );

    final json = jsonEncode(AppSettingsModel(original).toJson());
    final restored = AppSettingsModel.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    ).settings;

    expect(restored.themeMode, AppThemeMode.dark);
    expect(restored.accentColorId, 'blue');
    expect(restored.fontScaleId, 'large');
    expect(restored.animationLevel, AnimationLevel.reduced);
    expect(restored.backgroundImagePath, '/data/bg.jpg');
    expect(restored.notificationsEnabled, isTrue);
    expect(restored.dailyReminderEnabled, isTrue);
    expect(restored.dailyReminderMinutes, 8 * 60 + 15);
    expect(restored.milestoneNotificationsEnabled, isFalse);
    expect(restored.milestonesOf('s1'), {'pct25', 'pct50'});
    expect(restored.milestonesOf('s2'), {'day100'});
    expect(restored.milestonesOf('nobody'), isEmpty);
  });

  test('an app-wide unlocked set from an older build is parked as legacy', () {
    // Both older shapes at once: bare percents, and no soldier to attribute
    // them to. The controller hands them to whoever was active on load.
    final restored = AppSettingsModel.fromJson(const <String, dynamic>{
      'unlockedMilestones': [25, 50, 90],
    }).settings;

    expect(
      restored.unlockedMilestones,
      {AppSettings.legacyMilestonesKey: {'pct25', 'pct50', 'pct90'}},
    );
  });

  test('AppSettings falls back to defaults for empty json', () {
    final restored =
        AppSettingsModel.fromJson(const <String, dynamic>{}).settings;
    expect(restored.accentColorId, 'apricot');
    expect(restored.themeMode, AppThemeMode.system);
    expect(restored.unlockedMilestones, isEmpty);
  });
}
