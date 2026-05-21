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

final Map<String, Future<bool>> _existenceCache = {};

Future<bool> storedFileExistsAsync(String path) {
  if (path.isEmpty) return Future<bool>.value(false);
  if (_existenceCache.containsKey(path)) return _existenceCache[path]!;

  late final Future<bool> future;
  if (isContentUri(path)) {
    future = _pickerChannel
        .invokeMethod<bool>('uriExists', {'uri': path})
        .then((v) => v == true)
        .catchError((_) => false);
  } else {
    try {
      future = Future<bool>.value(File(path).existsSync());
    } catch (_) {
      future = Future<bool>.value(false);
    }
  }
  _existenceCache[path] = future;
  return future;
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
