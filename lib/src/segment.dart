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
///
/// [child] replaces the rendered label and icon with a widget of your own,
/// while [label] stays on as the segment's screen-reader text:
///
/// ```dart
/// Segment(label: 'Open', child: MyPill(count: 3))
/// ```
@immutable
class Segment {
  const Segment({
    required this.label,
    this.icon,
    this.iconWidget,
    this.child,
    this.badge,
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
  }) : assert(
          icon == null || iconWidget == null,
          'Give a segment either an icon or an iconWidget, not both',
        );

  /// The text shown in the segment.
  ///
  /// Still the segment's screen-reader text when [child] replaces what is
  /// drawn, unless [semanticLabel] overrides it.
  final String label;

  /// An optional icon shown before [label].
  final IconData? icon;

  /// A widget shown before [label], for icons this package cannot express as
  /// an [IconData] — an avatar, an SVG, a flag. Mutually exclusive with
  /// [icon], and sized by the widget itself rather than by
  /// `SegmentedControlTheme.iconSize`.
  final Widget? iconWidget;

  /// Replaces the icon and label entirely with a widget of your own.
  ///
  /// [label] is still used for semantics, and [badge] is still shown after it.
  final Widget? child;

  /// A widget shown after the label — a count, a dot, a status chip.
  final Widget? badge;

  /// Whether the segment can be selected. Disabled segments are dimmed and
  /// ignore taps.
  final bool enabled;

  /// Screen-reader label. Falls back to [label].
  final String? semanticLabel;

  /// Long-press tooltip. No tooltip is shown when null.
  final String? tooltip;

  /// A copy of this segment with the given fields replaced.
  Segment copyWith({
    String? label,
    IconData? icon,
    Widget? iconWidget,
    Widget? child,
    Widget? badge,
    bool? enabled,
    String? semanticLabel,
    String? tooltip,
  }) =>
      Segment(
        label: label ?? this.label,
        icon: icon ?? this.icon,
        iconWidget: iconWidget ?? this.iconWidget,
        child: child ?? this.child,
        badge: badge ?? this.badge,
        enabled: enabled ?? this.enabled,
        semanticLabel: semanticLabel ?? this.semanticLabel,
        tooltip: tooltip ?? this.tooltip,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Segment &&
          other.label == label &&
          other.icon == icon &&
          other.iconWidget == iconWidget &&
          other.child == child &&
          other.badge == badge &&
          other.enabled == enabled &&
          other.semanticLabel == semanticLabel &&
          other.tooltip == tooltip;

  @override
  int get hashCode => Object.hash(
        label,
        icon,
        iconWidget,
        child,
        badge,
        enabled,
        semanticLabel,
        tooltip,
      );

  @override
  String toString() => 'Segment($label${enabled ? '' : ', disabled'})';
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
    Widget? iconWidget,
    Widget? badge,
    bool enabled = true,
    String? semanticLabel,
    String? tooltip,
  }) : segment = Segment(
          label: label,
          icon: icon,
          iconWidget: iconWidget,
          badge: badge,
          enabled: enabled,
          semanticLabel: semanticLabel,
          tooltip: tooltip,
        );

  /// The segment in the control.
  final Segment segment;

  /// The body shown while [segment] is selected.
  final Widget child;

  /// A copy of this page with the given fields replaced.
  SegmentPage copyWith({Segment? segment, Widget? child}) =>
      SegmentPage(segment: segment ?? this.segment, child: child ?? this.child);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentPage && other.segment == segment && other.child == child;

  @override
  int get hashCode => Object.hash(segment, child);

  @override
  String toString() => 'SegmentPage(${segment.label})';
}
