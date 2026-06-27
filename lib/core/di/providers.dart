import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local_prefs_data_source.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/soldier_profile.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/soldiers_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/soldiers_repository.dart';
import '../../domain/usecases/backup_data.dart';
import '../../domain/usecases/compute_milestones.dart';
import '../../domain/usecases/compute_service_progress.dart';
import '../../domain/usecases/restore_data.dart';

/// Composition root: wires data sources, repositories, and use cases as
/// Riverpod providers.
///
/// [sharedPreferencesProvider] is overridden in `main` with the resolved
/// instance after async initialization.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final localPrefsDataSourceProvider = Provider<LocalPrefsDataSource>(
  (ref) => LocalPrefsDataSource(ref.watch(sharedPreferencesProvider)),
);

/// Settings loaded once at startup; overridden in `main` to seed controllers
/// synchronously and avoid a theme flash.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => throw UnimplementedError('initialSettingsProvider must be overridden'),
);

/// Soldiers loaded once at startup; overridden in `main`.
final initialSoldiersProvider = Provider<List<SoldierProfile>>(
  (ref) => throw UnimplementedError('initialSoldiersProvider must be overridden'),
);

/// Active soldier id loaded once at startup; overridden in `main`.
final initialActiveIdProvider = Provider<String?>(
  (ref) => throw UnimplementedError('initialActiveIdProvider must be overridden'),
);

final soldiersRepositoryProvider = Provider<SoldiersRepository>(
  (ref) => SoldiersRepositoryImpl(ref.watch(localPrefsDataSourceProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(localPrefsDataSourceProvider)),
);

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepositoryImpl(ref.watch(localPrefsDataSourceProvider)),
);

// Use cases (stateless, const).
final computeServiceProgressProvider = Provider<ComputeServiceProgress>(
  (ref) => const ComputeServiceProgress(),
);

final computeMilestonesProvider = Provider<ComputeMilestones>(
  (ref) => const ComputeMilestones(),
);

final backupDataProvider = Provider<BackupData>(
  (ref) => BackupData(ref.watch(backupRepositoryProvider)),
);

final restoreDataProvider = Provider<RestoreData>(
  (ref) => RestoreData(ref.watch(backupRepositoryProvider)),
);
