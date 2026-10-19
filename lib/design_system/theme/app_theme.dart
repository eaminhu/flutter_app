import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../tokens/app_typography.dart';

// Material remains the routing host; all visible controls use Forui's theme.
// TextTheme slots map to the AppTextStyle scale so Material widgets that read
// Theme.of(context).textTheme (dialogs, snackbars, pickers) stay on-brand.
ThemeData buildAppTheme(Brightness brightness) {
  final theme = brightness == Brightness.dark
      ? FTheme.neutral.dark.touch
      : FTheme.neutral.light.touch;
  final colors = theme.colors;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.primaryForeground,
          secondary: colors.secondary,
          onSecondary: colors.secondaryForeground,
          surface: colors.background,
          onSurface: colors.foreground,
          error: colors.destructive,
          onError: colors.destructiveForeground,
        ),
    scaffoldBackgroundColor: colors.background,
    textTheme: TextTheme(
      bodyMedium: theme.typography.body.md,
      bodySmall: AppTextStyle.caption(colors.foreground),
      titleLarge: AppTextStyle.title(colors.foreground),
      titleMedium: AppTextStyle.heading(colors.foreground),
      headlineLarge: AppTextStyle.display(colors.foreground),
    ),
  );
}
