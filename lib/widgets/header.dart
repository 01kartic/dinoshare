import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class LHeader extends StatefulWidget {
  final Widget child;
  final List<Widget> prefix;
  final List<Widget> suffix;
  final bool nested;

  const LHeader({
    super.key,
    this.child = const SizedBox.shrink(),
    this.prefix = const [],
    this.suffix = const [],
    this.nested = false,
  });

  @override
  State<LHeader> createState() => _LHeaderState();
}

class _LHeaderState extends State<LHeader> with SingleTickerProviderStateMixin {
  final GlobalKey _prefixKey = GlobalKey();
  final GlobalKey _suffixKey = GlobalKey();
  double _sideWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_updateSideWidth);
  }

  @override
  void didUpdateWidget(covariant LHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_updateSideWidth);
  }

  void _updateSideWidth(Duration _) {
    if (!mounted || !widget.nested) return;
    final prefixContext = _prefixKey.currentContext;
    final suffixContext = _suffixKey.currentContext;
    if (prefixContext == null || suffixContext == null) return;
    final prefixWidth = prefixContext.size?.width ?? 0;
    final suffixWidth = suffixContext.size?.width ?? 0;
    final maxWidth = math.max(prefixWidth, suffixWidth);
    if ((maxWidth - _sideWidth).abs() > 0.5) {
      setState(() {
        _sideWidth = maxWidth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final desktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    Widget titleWidget;
    if (widget.child is Text && (widget.child as Text).style == null) {
      titleWidget = Text(
        (widget.child as Text).data ?? '',
        style: theme.typography.lg.copyWith(
          fontSize:
              desktop
                  ? 18
                  : widget.nested
                  ? 24
                  : 30,
          color: theme.colors.foreground,
          fontWeight: desktop ? FontWeight.w600 : FontWeight.w700,
          height: 1.2,
        ),
      );
    } else {
      titleWidget = widget.child;
    }

    return Container(
      width: double.infinity,
      height: Platform.isMacOS ? 60 : 108,
      padding: EdgeInsets.fromLTRB(
        Platform.isMacOS ? 68 : 24,
        !desktop ? 62 : 8,
        Platform.isWindows || Platform.isLinux ? 102 : 24,
        10,
      ),
      child: Row(
        spacing: 4,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.prefix.isNotEmpty || (widget.nested && !desktop))
            SizedBox(
              width:
                  widget.nested && !desktop && _sideWidth > 0
                      ? _sideWidth
                      : null,
              child: Row(
                key: _prefixKey,
                mainAxisSize: MainAxisSize.min,
                children: widget.prefix,
              ),
            ),
          if (widget.nested && !desktop)
            Expanded(child: Center(child: titleWidget))
          else
            Expanded(
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 4),
                child: titleWidget,
              ),
            ),
          if (widget.suffix.isNotEmpty || (widget.nested && !desktop))
            SizedBox(
              width:
                  widget.nested && !desktop && _sideWidth > 0
                      ? _sideWidth
                      : null,
              child: Row(
                key: _suffixKey,
                mainAxisSize: MainAxisSize.min,
                children: widget.suffix,
              ),
            ),
        ],
      ),
    );
  }
}
