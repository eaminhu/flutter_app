import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Unified empty / error / placeholder status: muted 48dp icon, centered body
/// message and an optional FButton action, capped at 320dp so the copy never
/// touches the screen edges. The message is the primary content of the state,
/// so it uses onSurface rather than the muted variant.
class PageStatus extends StatelessWidget {
  const PageStatus({
    super.key,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: AppInsets.page,
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: colors.onSurfaceVariant),
                AppGap.v16,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.body(colors.onSurface),
                ),
                if (onAction != null && actionLabel != null) ...[
                  AppGap.v24,
                  FButton(onPress: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
