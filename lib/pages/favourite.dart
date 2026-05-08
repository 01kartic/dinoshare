import 'dart:io';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:dinoshare/widgets/incoming_transfer_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

class Favourite extends StatelessWidget {
  const Favourite({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return IncomingTransferOverlay(
      child: Container(
        color: theme.colors.secondary,
        child: Column(
        children: [
          DHeader(
            nested: true,
            prefix: [
              DButton(
                size: Platform.isMacOS ? DButtonSize.sm : DButtonSize.md,
                variant: DButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: Platform.isMacOS ? 20 : 24,
                ),
              ),
            ],
            title: 'Favourite Devices',
          ),
          Expanded(
            child: ValueListenableBuilder<List<FavouriteDevice>>(
              valueListenable: appFavouriteDevices,
              builder: (_, devices, _) {
                if (devices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
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
                              icon: HugeIcons.strokeRoundedStar,
                              size: 24,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                        DText(
                          'No Favourite Devices',
                          color: theme.colors.mutedForeground,
                        ),
                        DText(
                          'Tap the star icon when receiving\nto add a device here.',
                          color: theme.colors.mutedForeground.withAlpha(150),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 60)
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    DItemList(
                      borderRadius: BorderRadius.circular(14),
                      children: devices.map((device) {
                        return DItem(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          title: Text(device.name),
                          description: Text(_deviceTypeLabel(device.deviceType)),
                          prefix: HugeIcon(
                            icon: _deviceTypeIcon(device.deviceType),
                            size: 28,
                            color: theme.colors.primary,
                          ),
                          suffix: GestureDetector(
                            onTap: () => _confirmRemove(context, device.id, device.name),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedDelete02,
                              size: 20,
                              color: theme.colors.destructive,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: DText(
                        'Transfers from favourite devices will\nbe accepted automatically.',
                        size: DTextSize.sm,
                        color: theme.colors.mutedForeground.withAlpha(160),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _deviceTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'macos':
        return 'Mac';
      case 'windows':
        return 'Windows PC';
      case 'linux':
        return 'Linux';
      case 'ios':
        return 'iPhone';
      case 'android':
        return 'Android';
      default:
        return 'Device';
    }
  }

  List<List<dynamic>> _deviceTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'macos':
      case 'windows':
      case 'linux':
        return HugeIcons.strokeRoundedLaptop;
      case 'ios':
        return HugeIcons.strokeRoundedSmartPhone01;
      case 'android':
      default:
        return HugeIcons.strokeRoundedSmartPhone02;
    }
  }

  void _confirmRemove(BuildContext context, String id, String name) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Remove Favourite'),
        content: Text('Remove "$name" from favourite devices?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              removeFavouriteDevice(id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}