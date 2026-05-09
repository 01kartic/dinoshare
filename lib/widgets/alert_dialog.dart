import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

class DAlertDialogAction {
  const DAlertDialogAction({
    required this.label,
    required this.onPressed,
    this.variant = DButtonVariant.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final DButtonVariant variant;
}

class DAlertDialog extends StatelessWidget {
  const DAlertDialog({
    super.key,
    this.icon,
    this.iconColor,
    this.title,
    this.description,
    this.actions = const [],
  });

  final List<List<dynamic>>? icon;
  final Color? iconColor;
  final String? title;
  final TextSpan? description;
  final List<DAlertDialogAction> actions;

@override
  Widget build(BuildContext context) {
    assert(actions.length <= 3, 'Maximum 3 actions allowed');
    final theme = context.theme;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: ColoredBox(
                  color: theme.colors.foreground.withValues(alpha: 0.18),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(
                color: theme.colors.background,
                border: Border.all(color: theme.colors.border),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colors.foreground.withValues(alpha: 0.05),
                    offset: const Offset(1, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  if (icon != null) ...[
                    HugeIcon(
                      icon: icon!,
                      size: 32,
                      color: iconColor ?? theme.colors.foreground,
                    ),
                  ],
                  if (title != null) DText(title!, size: DTextSize.h3),
                  if (description != null)
                    DText.rich(
                      description!,
                      textAlign: TextAlign.center,
                    ),
                  if (actions.isNotEmpty)
                    Row(
                      spacing: 12,
                      children: actions.map((action) {
                        return Expanded(
                          child: DButton(
                            size: DButtonSize.sm,
                            variant: action.variant,
                            onPressed: () {
                              Navigator.of(context).pop();
                              action.onPressed();
                            },
                            child: Text(action.label),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void showDAlertDialog(
  BuildContext context, {
  List<List<dynamic>>? icon,
  Color? iconColor,
  String? title,
  TextSpan? description,
  List<DAlertDialogAction> actions = const [],
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (context, _, _) => DAlertDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        description: description,
        actions: actions,
      ),
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}