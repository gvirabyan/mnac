/// Contract for exporting/importing all app data as a portable JSON document,
/// and for reading/writing that document to a local file. Implemented in data.
abstract interface class BackupRepository {
  /// Serializes the current profile + settings into a JSON string.
  Future<String> exportJson();

  /// Restores profile + settings from a JSON string. Throws on invalid input.
  Future<void> importJson(String json);

  /// Writes a backup file to local storage and returns its path.
  Future<String> writeBackupFile();

  /// Reads a previously written backup file, returning its JSON, or null if the
  /// user cancelled selection.
  Future<String?> readBackupFile();
}
