import 'package:flutter/widgets.dart';

/// One segment of a [SlidingSegmentedControl].
///
/// A segment is a [label], an optional leading [icon], and whether it can be
/// picked. Use [Segment.new] for a plain text segment:
///
/// ```dart
/// const Segment(label: 'Open')
/// const Segment(label: 'Closed', icon: Icons.check, enabled: false)
/// ```
@immutable
class Segment {
  const Segment({
    required this.label,
    this.icon,
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
  });

  /// The text shown in the segment.
  final String label;

  /// An optional icon shown before [label].
  final IconData? icon;

  /// Whether the segment can be selected. Disabled segments are dimmed and
  /// ignore taps.
  final bool enabled;

  /// Screen-reader label. Falls back to [label].
  final String? semanticLabel;

  /// Long-press tooltip. No tooltip is shown when null.
  final String? tooltip;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Segment &&
          other.label == label &&
          other.icon == icon &&
          other.enabled == enabled &&
          other.semanticLabel == semanticLabel &&
          other.tooltip == tooltip;

  @override
  int get hashCode =>
      Object.hash(label, icon, enabled, semanticLabel, tooltip);
}

/// A [Segment] paired with the body shown while it is selected, for
/// [SegmentedBody].
@immutable
class SegmentPage {
  const SegmentPage({required this.segment, required this.child});

  /// Convenience constructor that builds the [segment] inline.
  SegmentPage.of({
    required String label,
    required this.child,
    IconData? icon,
    bool enabled = true,
    String? semanticLabel,
    String? tooltip,
  }) : segment = Segment(
          label: label,
          icon: icon,
          enabled: enabled,
          semanticLabel: semanticLabel,
          tooltip: tooltip,
        );

  /// The segment in the control.
  final Segment segment;

  /// The body shown while [segment] is selected.
  final Widget child;
}
