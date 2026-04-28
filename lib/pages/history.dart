import 'dart:io';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/util/fomart_icon.dart';
import 'package:dinoshare/util/stored_file.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/file_thumbnail.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      color: theme.colors.secondary,
      child: Column(
        children: [
          LHeader(
            nested: true,
            prefix: [
              LButton(
                size: Platform.isMacOS ? LButtonSize.sm : LButtonSize.md,
                variant: LButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: Platform.isMacOS ? 20 : 24,
                ),
              ),
            ],
            suffix: [
              LButton(
                size: Platform.isMacOS ? LButtonSize.sm : LButtonSize.md,
                variant: LButtonVariant.ghost,
                textColor: theme.colors.destructive,
                onPressed: () => clearTransferHistory(),
                child: Text('Clear'),
              ),
            ],
            child: Text('History'),
          ),
          Expanded(
            child: ValueListenableBuilder<List<TransferHistoryItem>>(
              valueListenable: appTransferHistory,
              builder: (_, history, _) {
                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colors.border.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedClipboardClock,
                              size: 24,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                        Text(
                          'No Transfer History',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colors.mutedForeground,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    Platform.isAndroid ? 24 : 16,
                  ),
                  children: [
                    LItemList(
                      borderRadius: BorderRadius.circular(14),
                      children:
                          history
                              .map((h) => _buildHistoryItem(theme, h))
                              .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(FThemeData theme, TransferHistoryItem h) {
    final sizeLabel = appDataUnit.value.formatSize(h.totalBytes);
    final directionLabel = h.isSending ? 'Sent to' : 'From';
    final previewFile = _bestPreviewFile(h);
    final openFile = _firstExistingFile(h);

    return LItem(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      prefix:
          previewFile == null || previewFile.path.isEmpty
              ? HugeIcon(
                icon:
                    h.isSending
                        ? HugeIcons.strokeRoundedShare03
                        : HugeIcons.strokeRoundedDownload02,
                size: 20,
                color: theme.colors.primary,
              )
              : FileThumbnail(
                path: previewFile.path,
                name: previewFile.name,
                size: 48,
                borderRadius: 8,
                iconColor: theme.colors.primary,
              ),
      title: Text(h.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      description: Text(
        '$directionLabel ${h.peerName} • ${_formatDate(h.completedAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      suffix: Text(
        sizeLabel,
        style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground),
      ),
      onPressed: openFile == null ? null : () => openStoredFile(openFile.path),
    );
  }

  HistoryFileItem? _bestPreviewFile(TransferHistoryItem h) {
    HistoryFileItem? firstExisting;
    for (final file in h.files) {
      if (!storedFileExists(file.path)) continue;
      firstExisting ??= file;
      final type = fileTypeIconData(file.name).fileType;
      if (type == 'Image' || type == 'Video') return file;
    }
    return firstExisting;
  }

  HistoryFileItem? _firstExistingFile(TransferHistoryItem h) {
    for (final file in h.files) {
      if (storedFileExists(file.path)) return file;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return _formatTime(date);

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
    if (isYesterday) return 'Yesterday, ${_formatTime(date)}';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
