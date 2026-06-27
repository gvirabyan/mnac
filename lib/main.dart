import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'data/datasources/local_prefs_data_source.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/soldiers_repository_impl.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage and preload data so the first frame is correct.
  final prefs = await SharedPreferences.getInstance();
  final dataSource = LocalPrefsDataSource(prefs);
  final settings = await SettingsRepositoryImpl(dataSource).load();
  final soldiersRepo = SoldiersRepositoryImpl(dataSource);
  final soldiers = await soldiersRepo.loadAll();
  final activeId = await soldiersRepo.loadActiveId();

  final notifications = NotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSettingsProvider.overrideWithValue(settings),
        initialSoldiersProvider.overrideWithValue(soldiers),
        initialActiveIdProvider.overrideWithValue(activeId),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const DepiTunApp(),
    ),
  );
}
