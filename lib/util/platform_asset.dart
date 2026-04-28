import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Returns the asset path for the current platform, given a filename.
String platformAsset(String filename) {
  if (kIsWeb) {
    return 'assets/web/$filename';
  } else if (Platform.isAndroid) {
    return 'assets/android/$filename';
  } else if (Platform.isIOS) {
    return 'assets/ios/$filename';
  } else if (Platform.isMacOS) {
    return 'assets/macos/$filename';
  } else if (Platform.isWindows) {
    return 'assets/windows/$filename';
  } else if (Platform.isLinux) {
    return 'assets/linux/$filename';
  }
  // Fallback to web assets if unknown
  return 'assets/web/$filename';
}
