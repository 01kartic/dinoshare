import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/pages/transfer.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/device_wait.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';

class Receive extends StatefulWidget {
  const Receive({super.key});

  @override
  State<Receive> createState() => _ReceiveState();
}

class _ReceiveState extends State<Receive> {
  final _scrollController = ScrollController();
  var _scrollOffset = 0.0;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (!appAlwaysReceive.value) {
      transferService.startReceiver(deviceName: appDeviceName.value);
    }
  }

  void _onScroll() => setState(() => _scrollOffset = _scrollController.offset);

  @override
  void dispose() {
    _scrollController.dispose();
    if (!appAlwaysReceive.value) {
      transferService.stopReceiver();
    }
    super.dispose();
  }

  Future<void> _accept(IncomingTransferRequest request) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final ok = await transferService.respondToIncoming(
      sessionId: request.sessionId,
      accept: true,
    );
    if (!mounted) return;
    setState(() => _accepting = false);
    if (ok) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => Transfer(role: TransferRole.receiving),
        ),
      );
    }
  }

  Future<void> _reject(IncomingTransferRequest request) async {
    await transferService.respondToIncoming(
      sessionId: request.sessionId,
      accept: false,
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
            child: Text('Receive'),
          ),
          _buildSelfIdentity(theme),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildSelfIdentity(FThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      child: ValueListenableBuilder<String>(
        valueListenable: appDeviceName,
        builder:
            (_, name, _) => Column(
              spacing: 8,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: theme.colors.foreground,
                    height: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colors.border, width: 1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _getDeviceTypeLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colors.mutedForeground,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildBody(FThemeData theme) {
    return ValueListenableBuilder<IncomingTransferRequest?>(
      valueListenable: transferService.incomingRequest,
      builder: (_, request, _) {
        final hasRequest = request != null;
        return LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            const cardHeight = 72.0;
            const bottomPadding = 32.0;
            final topPadding = (h - cardHeight - bottomPadding).clamp(
              20.0,
              double.infinity,
            );
            final fade =
                hasRequest ? (_scrollOffset / 120).clamp(0.0, 1.0) : 0.0;

            return Stack(
              children: [
                Positioned.fill(
                  bottom: 160,
                  child: Opacity(
                    opacity: 1.0 - fade * 0.6,
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.9,
                        child: LDeviceWait(
                          variant: LDeviceWaitVariant.primary,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSmartPhone01,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!hasRequest)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 72,
                    child: Text(
                      'Wait for another\ndevice to share',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  )
                else
                  ListView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(
                      top: topPadding,
                      bottom: bottomPadding,
                      left: 20,
                      right: 20,
                    ),
                    children: [
                      LItemList(
                        borderRadius: BorderRadius.circular(14),
                        children: [_buildRequestItem(theme, request)],
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRequestItem(FThemeData theme, IncomingTransferRequest request) {
    final fileCount = request.files.length;
    return LItem(
      title: Text(request.senderName),
      description: Text(
        '${_deviceTypeLabelFromRequest(request)} • $fileCount file${fileCount == 1 ? '' : 's'}',
      ),
      prefix: HugeIcon(
        icon: _deviceTypeIconFromRequest(request),
        size: 28,
        color: theme.colors.primary,
      ),
      suffix: Row(
        spacing: 10,
        children: [
          LButton(
            size: LButtonSize.sm,
            variant: LButtonVariant.destructive,
            onPressed: _accepting ? null : () => _reject(request),
            child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 20),
          ),
          LButton(
            size: LButtonSize.sm,
            variant: LButtonVariant.success,
            onPressed: _accepting ? null : () => _accept(request),
            child:
                _accepting
                    ? FCircularProgress.loader(
                      size: FCircularProgressSizeVariant.sm,
                    )
                    : HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 20),
          ),
        ],
      ),
    );
  }

  String _getDeviceTypeLabel() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iPhone';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isWindows) return 'Windows PC';
    return 'Device';
  }

  String _deviceTypeLabelFromRequest(IncomingTransferRequest request) {
    // Infer from sender name heuristic — not available in protocol, use generic
    return 'Device';
  }

  List<List<dynamic>> _deviceTypeIconFromRequest(
    IncomingTransferRequest request,
  ) {
    return HugeIcons.strokeRoundedSmartPhone02;
  }
}
