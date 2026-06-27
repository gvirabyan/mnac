import '../../core/utils/result.dart';
import '../repositories/backup_repository.dart';

/// Writes a local backup file and returns its path on success.
class BackupData {
  const BackupData(this._repository);
  final BackupRepository _repository;

  Future<Result<String>> call() async {
    try {
      final path = await _repository.writeBackupFile();
      return Success(path);
    } catch (_) {
      return const Failure('backup_failed');
    }
  }
}
