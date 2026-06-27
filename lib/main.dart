import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'data/datasources/local_prefs_data_source.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/soldiers_repository_impl.dart';
import 'presentation/home/home_controller.dart';
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

  // Preload motivational quotes so the home quote shows on the very first frame
  // (returning a non-Future from overrideWith makes the value available
  // synchronously, avoiding an empty banner right after adding a soldier).
  // Guarded so a malformed asset degrades to lazy loading instead of crashing.
  List<String>? quotes;
  try {
    final quotesRaw =
        await rootBundle.loadString('assets/quotes/quotes_hy.json');
    quotes = (jsonDecode(quotesRaw) as List).cast<String>();
  } catch (_) {
    quotes = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSettingsProvider.overrideWithValue(settings),
        initialSoldiersProvider.overrideWithValue(soldiers),
        initialActiveIdProvider.overrideWithValue(activeId),
        notificationServiceProvider.overrideWithValue(notifications),
        if (quotes != null) quotesProvider.overrideWith((ref) => quotes!),
      ],
      child: const DepiTunApp(),
    ),
  );
}
