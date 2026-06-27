import '../../core/utils/result.dart';
import '../repositories/backup_repository.dart';

/// Restores app data from a user-selected local backup file.
class RestoreData {
  const RestoreData(this._repository);
  final BackupRepository _repository;

  /// Returns [Success] with true if restored, false if the user cancelled.
  Future<Result<bool>> call() async {
    try {
      final json = await _repository.readBackupFile();
      if (json == null) return const Success(false);
      await _repository.importJson(json);
      return const Success(true);
    } catch (_) {
      return const Failure('restore_failed');
    }
  }
}
