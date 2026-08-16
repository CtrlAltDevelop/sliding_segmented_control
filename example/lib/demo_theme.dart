import 'package:flutter/material.dart';
import 'package:sliding_segmented_control/sliding_segmented_control.dart';

/// The demo's theme, with a [SegmentedControlTheme] registered so every
/// control in the app is styled in one place.
///
/// Drop the extension and the controls still render — they fall back to a
/// palette derived from the ambient `ColorScheme`.
ThemeData buildDemoTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [
      SegmentedControlTheme(
        trackColor: scheme.surfaceContainerLow,
        borderColor: scheme.outlineVariant,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        selectedLabelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        selectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
