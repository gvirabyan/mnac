import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:depitun/core/utils/app_files.dart';

void main() {
  late Directory oldDir;
  late Directory newDir;

  setUp(() async {
    oldDir = await Directory.systemTemp.createTemp('old_container');
    newDir = await Directory.systemTemp.createTemp('new_container');
    await AppFiles.init(documentsDir: newDir.path);
  });

  tearDown(() async {
    await oldDir.delete(recursive: true);
    await newDir.delete(recursive: true);
  });

  test('a path from the old container is moved to the new one', () async {
    await File(p.join(newDir.path, 'photo_1.jpg')).writeAsString('x');
    final old = p.join(oldDir.path, 'photo_1.jpg');

    expect(AppFiles.relocate(old), p.join(newDir.path, 'photo_1.jpg'));
  });

  test('a path that still works is kept', () async {
    final path = p.join(oldDir.path, 'photo_2.jpg');
    await File(path).writeAsString('x');

    expect(AppFiles.relocate(path), path);
  });

  test('a file missing everywhere and null are left alone', () {
    final gone = p.join(oldDir.path, 'gone.jpg');

    expect(AppFiles.relocate(gone), gone);
    expect(AppFiles.relocate(null), isNull);
  });
}
