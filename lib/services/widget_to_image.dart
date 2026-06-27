import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';


/// Captures the [RenderRepaintBoundary] behind [key] to a PNG file in the
/// temporary directory and returns its path.
///
/// Used to turn an on-screen share card into a shareable image. The boundary
/// must already be laid out and painted (i.e. visible in the tree).
Future<String> captureBoundaryToPng(
  GlobalKey key, {
  double pixelRatio = 3.0,
  String fileName = 'depitun_share.png',
}) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('Share boundary is not attached to the render tree');
  }

  final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode the share image');
    }
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  } finally {
    image.dispose();
  }
}
