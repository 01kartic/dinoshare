import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/util/fomart_icon.dart';
import 'package:dinoshare/util/platform_asset.dart';
import 'package:dinoshare/util/stored_file.dart';
import 'package:dinoshare/widgets/huge_button.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/file_thumbnail.dart';
import 'package:dinoshare/style/theme.dart';
import 'package:dinoshare/pages/history.dart';
import 'package:dinoshare/pages/settings.dart';
import 'package:dinoshare/pages/share.dart';
import 'package:dinoshare/pages/receive.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Good Morning';
  if (hour >= 12 && hour < 17) return 'Good Afternoon';
  if (hour >= 17 && hour < 21) return 'Good Evening';
  return 'Good Night';
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );

    return Container(
      color: theme.colors.secondary,
      child: Column(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colors.background,
                  border: Border(
                    bottom: BorderSide(color: theme.colors.border),
                  ),
                ),
                child: Column(
                  children: [
                    LHeader(
                      suffix: [
                        LButton(
                          size:
                              Platform.isMacOS
                                  ? LButtonSize.sm
                                  : LButtonSize.md,
                          variant: LButtonVariant.ghost,
                          onPressed:
                              () => Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) => const Settings(),
                                ),
                              ),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSettings01,
                            size: Platform.isMacOS ? 20 : 24,
                          ),
                        ),
                      ],
                      child: Text(getGreeting()),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(
                        20,
                        Platform.isMacOS ? 8 : 16,
                        20,
                        20,
                      ),
                      child: Row(
                        spacing: 20,
                        children: [
                          Expanded(
                            child: LHugeButton(
                              label: 'Share',
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedShare03,
                              ),
                              onPressed: () async {
                                await pickShareTargets(reset: true);
                                if (!mounted) return;
                                if (appShareItems.value.isEmpty) return;
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (_) => const Share(),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: LHugeButton(
                              variant: LHugeButtonVariant.outline,
                              label: 'Receive',
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedDownload02,
                              ),
                              onPressed:
                                  () => Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (_) => const Receive(),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder<List<TransferHistoryItem>>(
              valueListenable: appTransferHistory,
              builder: (_, history, _) {
                final recent =
                    history
                        .where((h) => _isToday(h.completedAt))
                        .take(5)
                        .toList();

                // ── Shared widgets ─────────────────────────────────────────
                final deviceChip = ValueListenableBuilder<String>(
                  valueListenable: appDeviceName,
                  builder:
                      (_, name, _) => ValueListenableBuilder<String>(
                        valueListenable: appDeviceTypeLabel,
                        builder:
                            (_, typeLabel, _) => Padding(
                              padding: EdgeInsetsGeometry.fromLTRB(
                                20,
                                16,
                                20,
                                0,
                              ),
                              child: LItem(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                spacing: 10,
                                prefix: HugeIcon(
                                  icon: _deviceIcon(typeLabel),
                                  color: lCustom.success,
                                  size: 20,
                                ),
                                suffix: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                      ),
                );

                final historyHeader = Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'History',
                        style: theme.typography.sm.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colors.mutedForeground,
                          height: 1.2,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap:
                            () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => const History(),
                              ),
                            ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'View All',
                            style: theme.typography.sm.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: lCustom.info,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                final footer = [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 32, 0, 0),
                    child: Column(
                      spacing: 8,
                      children: [
                        Row(
                          spacing: 4,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Made with',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colors.mutedForeground,
                                height: 1.2,
                              ),
                            ),
                            Image(
                              image: AssetImage(platformAsset('Red_Heart.png')),
                              width: 18,
                            ),
                          ],
                        ),
                        Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colors.mutedForeground.withAlpha(180),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: Platform.isAndroid ? 16 : 0,
                    ),
                    child: Image(
                      image: AssetImage(
                        platformAsset(
                          theme.colors.brightness == Brightness.dark
                              ? 'Dino_Footer_Dark.png'
                              : 'Dino_Footer_Light.png',
                        ),
                      ),
                    ),
                  ),
                ];

                // ── Empty state ────────────────────────────────────────────
                if (recent.isEmpty) {
                  return Column(
                    children: [
                      deviceChip,
                      historyHeader,
                      Expanded(
                        child: Center(
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
                                'No Transfers Today',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colors.mutedForeground,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...footer,
                    ],
                  );
                }

                // ── History + scroll ───────────────────────────────────────
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: deviceChip),
                    SliverToBoxAdapter(child: historyHeader),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: LItemList(
                          borderRadius: BorderRadius.circular(14),
                          children:
                              recent
                                  .map(
                                    (h) => _buildHistoryItem(context, theme, h),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: footer,
                      ),
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

  Widget _buildHistoryItem(
    BuildContext context,
    FThemeData theme,
    TransferHistoryItem h,
  ) {
    final icon =
        h.isSending
            ? HugeIcons.strokeRoundedShare03
            : HugeIcons.strokeRoundedDownload02;
    final sizeLabel = appDataUnit.value.formatSize(h.totalBytes);
    return LItem(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      prefix: _buildHistoryPrefix(theme, h, icon),
      title: Text(h.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      description: Text(
        '${h.isSending ? 'Sent to' : 'From'} ${h.peerName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      suffix: Text(
        sizeLabel,
        style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground),
      ),
    );
  }

  Widget _buildHistoryPrefix(
    FThemeData theme,
    TransferHistoryItem h,
    List<List<dynamic>> fallbackIcon,
  ) {
    final previewFile = _bestPreviewFile(h);
    if (previewFile == null || previewFile.path.isEmpty) {
      return HugeIcon(
        icon: fallbackIcon,
        size: 20,
        color: theme.colors.primary,
      );
    }
    return FileThumbnail(
      path: previewFile.path,
      name: previewFile.name,
      size: 48,
      borderRadius: 8,
      iconColor: theme.colors.primary,
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<List<dynamic>> _deviceIcon(String typeLabel) {
    final l = typeLabel.toLowerCase();
    if (l.contains('macbook') || l.contains('laptop')) {
      return HugeIcons.strokeRoundedLaptop;
    }
    if (l.contains('imac') ||
        l.contains('mac mini') ||
        l.contains('mac pro') ||
        l.contains('mac studio') ||
        l.contains('windows') ||
        l.contains('linux') ||
        l.contains('desktop')) {
      return HugeIcons.strokeRoundedComputer;
    }
    if (l.contains('ipad') || l.contains('tablet')) {
      return HugeIcons.strokeRoundedTablet01;
    }
    return HugeIcons.strokeRoundedSmartPhone02;
  }
}
