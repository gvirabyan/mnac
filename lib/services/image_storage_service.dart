import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies user-picked images into the app's documents directory so they
/// persist independently of the original gallery file. Only the resulting
/// path is stored; nothing leaves the device.
class ImageStorageService {
  const ImageStorageService();

  /// Copies [sourcePath] into app storage under a name prefixed with [prefix],
  /// returning the new absolute path.
  Future<String> savePickedImage(
    String sourcePath, {
    required String prefix,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(sourcePath);
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(dir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Deletes a stored image if it exists (best-effort).
  Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final imageStorageServiceProvider = Provider<ImageStorageService>(
  (ref) => const ImageStorageService(),
);
