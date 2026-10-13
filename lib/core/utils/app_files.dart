import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps stored paths to files in the app's documents directory valid.
///
/// Photos are saved as absolute paths, but on iOS the documents directory
/// moves to a new container on every app update, so an old path points
/// nowhere while the file itself is still there under the new directory.
abstract final class AppFiles {
  AppFiles._();

  static String? _documentsDir;

  /// Must run before stored settings and soldiers are loaded. Tests pass
  /// [documentsDir] instead of asking the platform.
  static Future<void> init({String? documentsDir}) async {
    _documentsDir =
        documentsDir ?? (await getApplicationDocumentsDirectory()).path;
  }

  /// Returns [path] re-pointed at the current documents directory when the
  /// file is no longer at [path] but is there under the same name.
  static String? relocate(String? path) {
    final dir = _documentsDir;
    if (path == null || dir == null || File(path).existsSync()) return path;
    final moved = p.join(dir, p.basename(path));
    return File(moved).existsSync() ? moved : path;
  }
}
