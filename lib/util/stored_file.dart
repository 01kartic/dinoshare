import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

const MethodChannel _pickerChannel = MethodChannel('dinoshare/picker');

bool isContentUri(String path) => path.startsWith('content://');

bool storedFileExists(String path) {
  if (path.isEmpty) return false;
  if (isContentUri(path)) return true;
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}

Future<Uint8List?> readStoredFileBytes(String path) async {
  if (path.isEmpty) return null;
  if (isContentUri(path)) {
    final bytes = await _pickerChannel.invokeMethod<Uint8List>('readUriBytes', {
      'uri': path,
    });
    return bytes;
  }
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

Future<void> openStoredFile(String path) async {
  if (path.isEmpty) return;
  if (isContentUri(path)) {
    try {
      await _pickerChannel.invokeMethod<bool>('openUri', {'uri': path});
      return;
    } catch (_) {
      return;
    }
  }
  if (!storedFileExists(path)) return;
  await OpenFilex.open(path);
}
