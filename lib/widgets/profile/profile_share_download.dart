import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

String profileShareFilename(String name) {
  final slug = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'dinq-profile.png' : '$slug-dinq-profile.png';
}

Future<void> shareProfileBoundary({
  required GlobalKey boundaryKey,
  required String profileName,
  Rect? sharePositionOrigin,
}) async {
  await WidgetsBinding.instance.endOfFrame;
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    throw StateError('Profile preview is not ready.');
  }

  final image = await boundary.toImage(pixelRatio: 2);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) throw StateError('Unable to encode profile image.');

  final directory = await getTemporaryDirectory();
  final safeFilename = profileShareFilename(profileName);
  final file = File('${directory.path}/$safeFilename');
  await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: safeFilename,
    sharePositionOrigin: sharePositionOrigin,
  );
}
