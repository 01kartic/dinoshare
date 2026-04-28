import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:dinoshare/widgets/switch.dart';
import 'package:dinoshare/widgets/theme_switcher.dart';
import 'package:dinoshare/util/platform_asset.dart';
import 'package:url_launcher/url_launcher.dart';

import '../style/theme.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late TextEditingController _nameController;
  String _localIp = '';

  static const _unitOptions = DataUnitType.values;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: appDeviceName.value);
    _loadIp();
  }

  Future<void> _loadIp() async {
    final ip = await transferService.localIpAddress();
    if (mounted) setState(() => _localIp = ip);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiveFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose receive folder',
    );
    if (path != null && path.trim().isNotEmpty) {
      await setReceivePath(path.trim());
      if (mounted) setState(() {});
    }
  }

  Future<void> _openSponsorLink() async {
    final url = 'https://github.com/sponsors/01kartic';
    final uri = Uri.parse(url);

    if (Platform.isMacOS) {
      await Process.start('open', [url]);
      return;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [url]);
      return;
    }
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url]);
      return;
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // ignore: avoid_print
        print('Could not open sponsor link: $uri');
      }
    } catch (err) {
      // ignore: avoid_print
      print('Failed to launch URL with url_launcher: $err');
    }
  }

  void _showUnitPicker() {
    showFSheet(
      side: FLayout.btt,
      context: context,
      mainAxisMaxRatio: null,
      builder: (ctx) {
        final theme = ctx.theme;
        final lCustom = dinoCustomColors(
          dark: theme.colors.brightness == Brightness.dark,
        );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder:
              (ctx2, controller) => Container(
                decoration: BoxDecoration(
                  color: theme.colors.secondary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(
                    color: theme.colors.border,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  spacing: 12,
                  children: [
                    Container(
                      width: 52,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          Padding(
                            padding: EdgeInsetsGeometry.all(12),
                            child: Text(
                              'Select Type',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colors.mutedForeground,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: LItemList(
                              borderRadius: BorderRadius.circular(14),
                              children:
                                  _unitOptions.map((unit) {
                                    return ValueListenableBuilder<DataUnitType>(
                                      valueListenable: appDataUnit,
                                      builder:
                                          (_, current, _) => LItem(
                                            title: Text(unit.label),
                                            prefix:
                                                current == unit
                                                    ? HugeIcon(
                                                      icon:
                                                          HugeIcons
                                                              .strokeRoundedTick02,
                                                      size: 20,
                                                      color: lCustom.success,
                                                      strokeWidth: 2,
                                                    )
                                                    : SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                    ),
                                            onPressed: () async {
                                              await setDataUnit(unit);
                                              // if (ctx2.mounted) {
                                              //   Navigator.of(ctx2).pop();
                                              // }
                                            },
                                          ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
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
            child: Text('Settings'),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                  child: Column(
                    spacing: 24,
                    children: [
                      // ── General ────────────────────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Padding(
                            padding: EdgeInsetsGeometry.fromLTRB(12, 0, 12, 0),
                            child: Text(
                              'General',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colors.mutedForeground,
                                height: 1.2,
                              ),
                            ),
                          ),
                          LItemList(
                            borderRadius: BorderRadius.circular(14),
                            children: [
                              // Device name
                              LItem(
                                title: Text('Device Name'),
                                suffix: SizedBox(
                                  width: 160,
                                  child: FTextField(
                                    control: FTextFieldControl.managed(
                                      controller: _nameController,
                                    ),
                                    hint: 'LAFs Device',
                                    textAlign: TextAlign.end,
                                    maxLength: 32,
                                    style: FTextFieldStyleDelta.delta(
                                      color: FVariantsValueDelta.delta([
                                        FVariantValueDeltaOperation.all(
                                          Colors.transparent,
                                        ),
                                      ]),
                                      border: FVariantsValueDelta.delta([
                                        FVariantValueDeltaOperation.all(
                                          InputBorder.none,
                                        ),
                                      ]),
                                      contentPadding:
                                          EdgeInsetsGeometryDelta.value(
                                            EdgeInsets.zero,
                                          ),
                                      contentTextStyle: FVariantsDelta.delta([
                                        FVariantOperation.all(
                                          TextStyleDelta.delta(
                                            letterSpacing: 0,
                                            fontSize: 14,
                                            color: theme.colors.mutedForeground,
                                          ),
                                        ),
                                      ]),
                                      hintTextStyle: FVariantsDelta.delta([
                                        FVariantOperation.all(
                                          TextStyleDelta.delta(
                                            letterSpacing: 0,
                                            fontSize: 14,
                                            color: theme.colors.mutedForeground
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ]),
                                    ),
                                    onSubmit: (val) => setDeviceName(val),
                                    onEditingComplete:
                                        () =>
                                            setDeviceName(_nameController.text),
                                  ),
                                ),
                              ),
                              // Receive folder
                              ValueListenableBuilder<String?>(
                                valueListenable: appReceivePath,
                                builder:
                                    (_, path, _) => LItem(
                                      title: Text('Receive Folder'),
                                      description: Text(
                                        path ?? 'Downloads/Dino',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      suffix: HugeIcon(
                                        icon:
                                            HugeIcons.strokeRoundedArrowRight01,
                                        size: 16,
                                        color: theme.colors.foreground,
                                      ),
                                      onPressed: _pickReceiveFolder,
                                    ),
                              ),
                              // Data unit type
                              ValueListenableBuilder<DataUnitType>(
                                valueListenable: appDataUnit,
                                builder:
                                    (_, unit, _) => LItem(
                                      title: Text('Data Unit Type'),
                                      suffix: Row(
                                        spacing: 6,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            unit.label,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  theme.colors.mutedForeground,
                                            ),
                                          ),
                                          HugeIcon(
                                            icon:
                                                HugeIcons
                                                    .strokeRoundedArrowDown01,
                                            size: 16,
                                            color: theme.colors.mutedForeground,
                                          ),
                                        ],
                                      ),
                                      onPressed: _showUnitPicker,
                                    ),
                              ),
                              // Language (skipped — placeholder)
                              // LItem(
                              //   title: Text('Language'),
                              //   suffix: Row(
                              //     spacing: 6,
                              //     mainAxisAlignment: MainAxisAlignment.center,
                              //     children: [
                              //       Text(
                              //         'English',
                              //         style: TextStyle(
                              //           fontSize: 14,
                              //           color: theme.colors.mutedForeground,
                              //         ),
                              //       ),
                              //       HugeIcon(
                              //         icon: HugeIcons.strokeRoundedArrowDown01,
                              //         size: 16,
                              //         color: theme.colors.mutedForeground,
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                      // ── Theme ──────────────────────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Padding(
                            padding: EdgeInsetsGeometry.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              'Theme',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colors.mutedForeground,
                                height: 1.2,
                              ),
                            ),
                          ),
                          LThemeSwitcher(),
                        ],
                      ),
                      // ── Advanced ───────────────────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Padding(
                            padding: EdgeInsetsGeometry.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              'Advance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colors.mutedForeground,
                                height: 1.2,
                              ),
                            ),
                          ),
                          LItemList(
                            borderRadius: BorderRadius.circular(14),
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: appAlwaysReceive,
                                builder:
                                    (_, val, _) => LItem(
                                      title: Text('Always Receive'),
                                      suffix: LSwitch(
                                        on: val,
                                        onPressed: () => setAlwaysReceive(!val),
                                        variant: LSwitchVariant.success,
                                      ),
                                    ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: appFullPowerMode,
                                builder:
                                    (_, val, _) => LItem(
                                      title: Text('Full Power Mode'),
                                      suffix: LSwitch(
                                        on: val,
                                        onPressed: () => setFullPowerMode(!val),
                                        variant: LSwitchVariant.success,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // ── About ──────────────────────────────────────────────
                      // Column(
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   spacing: 8,
                      //   children: [
                      //     LItemList(
                      //       borderRadius: BorderRadius.circular(14),
                      //       children: [
                      //         LItem(
                      //           title: Text('About'),
                      //           suffix: HugeIcon(
                      //             icon: HugeIcons.strokeRoundedArrowRight01,
                      //             size: 16,
                      //             color: theme.colors.foreground,
                      //           ),
                      //         ),
                      //         LItem(
                      //           title: Text('Help'),
                      //           suffix: HugeIcon(
                      //             icon: HugeIcons.strokeRoundedArrowRight01,
                      //             size: 16,
                      //             color: theme.colors.foreground,
                      //           ),
                      //         ),
                      //         LItem(
                      //           title: Text('Privacy Policy'),
                      //           suffix: HugeIcon(
                      //             icon: HugeIcons.strokeRoundedArrowRight01,
                      //             size: 16,
                      //             color: theme.colors.foreground,
                      //           ),
                      //         ),
                      //         LItem(
                      //           padding: EdgeInsets.fromLTRB(20, 10, 12, 10),
                      //           title: Text('Support Dino'),
                      //           suffix: LButton(
                      //             size: LButtonSize.xs,
                      //             variant: LButtonVariant.success,
                      //             child: Text('Donate'),
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //     Padding(
                      //           padding: EdgeInsetsGeometry.symmetric(
                      //             horizontal: 16,
                      //             vertical: 12,
                      //           ),
                      //           child: Center(
                      //             child: Text(
                      //               _localIp.isNotEmpty ? _localIp : '—',
                      //               style: TextStyle(
                      //                 fontSize: 14,
                      //                 fontWeight: FontWeight.w500,
                      //                 color: theme.colors.mutedForeground,
                      //                 height: 1.2,
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 48, 0, 0),
                  child: Column(
                    spacing: 8,
                    children: [
                      Padding(
                        padding: EdgeInsetsGeometry.only(bottom: 32),
                        child: LButton(
                          onPressed: _openSponsorLink,
                          size: LButtonSize.sm,
                          prefix: HugeIcon(
                            icon: HugeIcons.strokeRoundedFavourite,
                            color: Color(0xFFDB61A2),
                            size: 18,
                          ),
                          style: LButtonStyle(
                            width: 104,
                            gradient: LinearGradient(
                              colors: [
                                theme.colors.foreground,
                                theme.colors.foreground,
                              ],
                            ),
                            textColor: theme.colors.background,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colors.foreground.withValues(
                                  alpha: 0.24,
                                ),
                                offset: const Offset(1, 2),
                                blurRadius: 4,
                              ),
                              BoxShadow(
                                color: theme.colors.foreground.withValues(
                                  alpha: 1,
                                ),
                                offset: Offset.zero,
                                blurRadius: 0,
                                spreadRadius: 1,
                              ),
                            ],
                            borderColor: theme.colors.foreground,
                            padding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: Text('Sponsor'),
                        ),
                      ),
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
                Image(
                  image: AssetImage(
                    platformAsset(
                      theme.colors.brightness == Brightness.dark
                          ? 'Dino_Footer_Dark.png'
                          : 'Dino_Footer_Light.png',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
