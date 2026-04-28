part of 'state_index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// File / folder selection
// ─────────────────────────────────────────────────────────────────────────────

final appPickingActive = ValueNotifier<bool>(false);

// Method channel to our native Android picker (no-copy via file descriptor).
const _pickerChannel = MethodChannel('dinoshare/picker');

Future<void> pickShareTargets({bool reset = false}) async {
  if (appPickingActive.value) return;
  appPickingActive.value = true;
  try {
    await _pickShareTargets(reset: reset);
  } finally {
    appPickingActive.value = false;
  }
}

// Wraps a FilePicker call and retries once after clearing state if the plugin
// reports already_active (e.g. after a hot restart).
Future<T?> _pickerCall<T>(Future<T?> Function() call) async {
  try {
    return await call();
  } on PlatformException catch (e) {
    if (e.code != 'already_active') rethrow;
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (_) {}
    try {
      return await call();
    } on PlatformException catch (_) {
      return null;
    }
  }
}

Future<void> _pickShareTargets({bool reset = false}) async {
  final nextItems = <SelectedShareItem>[if (!reset) ...appShareItems.value];

  if (Platform.isMacOS) {
    // ── macOS: allow any file or directory ───────────────────────────────────
    final result = await _pickerCall(
      () => FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withReadStream: false,
      ),
    );
    if (result != null) {
      for (final pf in result.files) {
        final path = pf.path;
        if (path == null || path.trim().isEmpty) continue;
        final norm = p.normalize(path);
        if (nextItems.any((i) => p.normalize(i.path) == norm)) continue;

        final entityType = FileSystemEntity.typeSync(norm);
        if (entityType == FileSystemEntityType.directory) {
          await _addDirectory(norm, nextItems);
        } else if (entityType == FileSystemEntityType.file) {
          final file = File(norm);
          final stat = await file.stat();
          final name = p.basename(norm);
          nextItems.add(
            SelectedShareItem(
              id: _shareId(nextItems.length),
              path: norm,
              name: name,
              isDirectory: false,
              files: [
                TransferFileEntry(
                  sourcePath: norm,
                  relativePath: name,
                  name: name,
                  sizeBytes: stat.size,
                  topLevelName: name,
                ),
              ],
            ),
          );
        }
      }
    }
    if (nextItems.length == (reset ? 0 : appShareItems.value.length)) {
      final dirPath = await _pickerCall(
        () => FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Pick folder to share',
        ),
      );
      if (dirPath != null && dirPath.trim().isNotEmpty) {
        await _addDirectory(p.normalize(dirPath), nextItems);
      }
    }
  } else if (Platform.isAndroid) {
    // ── Android: native picker via file descriptor — zero copy ───────────────
    // Close PFDs from any previous session before opening a new one.
    try {
      await _pickerChannel.invokeMethod<void>('closeAll');
    } catch (_) {}

    List<_AndroidFileEntry>? androidFiles;
    try {
      final raw = await _pickerChannel.invokeMethod<List<dynamic>>('pick');
      if (raw != null) {
        androidFiles =
            raw
                .cast<Map<dynamic, dynamic>>()
                .map(
                  (m) => _AndroidFileEntry(
                    path: m['path'] as String,
                    uri: (m['uri'] as String?) ?? (m['path'] as String),
                    name: m['name'] as String,
                    size: (m['size'] as num).toInt(),
                  ),
                )
                .toList();
      }
    } on PlatformException catch (_) {
      // Fall through to folder picker below.
    }

    if (androidFiles != null) {
      for (final af in androidFiles) {
        // af.path is /proc/self/fd/{n} — readable immediately, no copy.
        if (nextItems.any((i) => i.path == af.path)) continue;
        nextItems.add(
          SelectedShareItem(
            id: _shareId(nextItems.length),
            path: af.path,
            name: af.name,
            isDirectory: false,
            files: [
              TransferFileEntry(
                sourcePath: af.path,
                storedPath: af.uri,
                relativePath: af.name,
                name: af.name,
                sizeBytes: af.size,
                topLevelName: af.name,
              ),
            ],
          ),
        );
      }
    }

    if (nextItems.length == (reset ? 0 : appShareItems.value.length)) {
      final dirPath = await _pickerCall(
        () => FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Pick folder to share',
        ),
      );
      if (dirPath != null && dirPath.trim().isNotEmpty) {
        await _addDirectory(p.normalize(dirPath), nextItems);
      }
    }
  } else {
    // ── iOS / Windows: file picker ───────────────────────────────────────────
    final result = await _pickerCall(
      () => FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
      ),
    );
    if (result != null) {
      for (final pf in result.files) {
        final path = pf.path;
        if (path == null) continue;
        final norm = p.normalize(path);
        if (nextItems.any((i) => p.normalize(i.path) == norm)) continue;
        nextItems.add(
          SelectedShareItem(
            id: _shareId(nextItems.length),
            path: norm,
            name: pf.name,
            isDirectory: false,
            files: [
              TransferFileEntry(
                sourcePath: norm,
                relativePath: pf.name,
                name: pf.name,
                sizeBytes: pf.size,
                topLevelName: pf.name,
              ),
            ],
          ),
        );
      }
    }
    if (nextItems.length == (reset ? 0 : appShareItems.value.length)) {
      final dirPath = await _pickerCall(
        () => FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Pick folder to share',
        ),
      );
      if (dirPath != null && dirPath.trim().isNotEmpty) {
        await _addDirectory(p.normalize(dirPath), nextItems);
      }
    }
  }

  appShareItems.value = nextItems;
}

Future<void> _addDirectory(
  String norm,
  List<SelectedShareItem> nextItems,
) async {
  if (nextItems.any((i) => p.normalize(i.path) == norm)) return;
  final root = Directory(norm);
  final folderName = p.basename(norm);
  final files = await _expandDirectory(root, folderName);
  if (files.isNotEmpty) {
    nextItems.add(
      SelectedShareItem(
        id: _shareId(nextItems.length),
        path: norm,
        name: folderName,
        isDirectory: true,
        files: files,
      ),
    );
  }
}

void removeShareTarget(String id) {
  appShareItems.value = appShareItems.value.where((i) => i.id != id).toList();
}

TransferSelection currentSelection() {
  final items = appShareItems.value;
  final files = items.expand((i) => i.files).toList();
  final total = files.fold<int>(0, (s, f) => s + f.sizeBytes);
  return TransferSelection(
    files: files,
    topLevelCount: items.length,
    totalBytes: total,
    labels: items.map((i) => i.name).toList(),
  );
}

Future<List<TransferFileEntry>> _expandDirectory(
  Directory root,
  String topLevelName,
) async {
  final entries = <TransferFileEntry>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final stat = await entity.stat();
    final relInside = p.relative(entity.path, from: root.path);
    entries.add(
      TransferFileEntry(
        sourcePath: entity.path,
        relativePath: p.join(topLevelName, relInside),
        name: p.basename(entity.path),
        sizeBytes: stat.size,
        topLevelName: topLevelName,
      ),
    );
  }
  return entries;
}

String _shareId(int n) => '${DateTime.now().microsecondsSinceEpoch}_$n';

class _AndroidFileEntry {
  final String path;
  final String uri;
  final String name;
  final int size;
  const _AndroidFileEntry({
    required this.path,
    required this.uri,
    required this.name,
    required this.size,
  });
}
