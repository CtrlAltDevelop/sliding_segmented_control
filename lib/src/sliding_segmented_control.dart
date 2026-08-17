import 'package:material_ui/material_ui.dart';

import 'segment.dart';
import 'segmented_control_theme.dart';

/// The default duration of the indicator slide.
const Duration kSegmentedControlDuration = Duration(milliseconds: 250);

/// A segmented control whose selection is marked by a pill that slides between
/// segments, rather than by a highlighted button.
///
/// The segments share the available width equally, so the control fills its
/// parent horizontally. Colours, shapes and metrics come from
/// [SegmentedControlTheme]; per-instance overrides on the widget win over it.
///
/// ```dart
/// SlidingSegmentedControl(
///   segments: const [Segment(label: 'Buy'), Segment(label: 'Sell')],
///   selectedIndex: index,
///   onSegmentChanged: (i) => setState(() => index = i),
/// )
/// ```
///
/// The indicator is aligned along the text direction, so the control reads
/// correctly under [TextDirection.rtl] with no extra work.
class SlidingSegmentedControl extends StatelessWidget {
  const SlidingSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentChanged,
    this.enabled = true,
    this.duration = kSegmentedControlDuration,
    this.curve = Curves.easeInOut,
    this.height,
    this.padding,
    this.trackRadius,
    this.indicatorRadius,
    this.trackShape,
    this.indicatorShape,
    this.labelStyle,
    this.selectedLabelStyle,
    this.trackColor,
    this.indicatorColor,
    this.selectedLabelColor,
    this.unselectedLabelColor,
    this.semanticLabel,
  })  : assert(segments.length > 0, 'segments must not be empty'),
        assert(
          selectedIndex >= 0 && selectedIndex < segments.length,
          'selectedIndex must be a valid index into segments',
        );

  /// The segments, laid out in order across the track. Must not be empty.
  final List<Segment> segments;

  /// Index of the selected segment, into [segments].
  final int selectedIndex;

  /// Called with the tapped index. Not called for the already-selected segment
  /// or for a disabled one.
  final ValueChanged<int> onSegmentChanged;

  /// Whether the whole control accepts taps. Disabling it dims every label.
  final bool enabled;

  /// How long the indicator takes to slide.
  final Duration duration;

  /// The curve the indicator slides on.
  final Curve curve;

  /// Overrides [SegmentedControlTheme.height].
  final double? height;

  /// Overrides [SegmentedControlTheme.trackPadding].
  final EdgeInsetsGeometry? padding;

  /// Overrides [SegmentedControlTheme.trackRadius]. Any
  /// [BorderRadiusGeometry] works, [BorderRadiusDirectional] included.
  final BorderRadiusGeometry? trackRadius;

  /// Overrides [SegmentedControlTheme.indicatorRadius], on the same terms.
  final BorderRadiusGeometry? indicatorRadius;

  /// Overrides [SegmentedControlTheme.trackShape], and with it [trackRadius].
  ///
  /// Any [ShapeBorder] at all, which is how a host brings its own corner
  /// geometry — a `StadiumBorder`, or a squircle from a package such as
  /// `figma_squircle` — without this package depending on it.
  final ShapeBorder? trackShape;

  /// Overrides [SegmentedControlTheme.indicatorShape], and with it
  /// [indicatorRadius]. Any [ShapeBorder], as for [trackShape].
  final ShapeBorder? indicatorShape;

  /// Overrides [SegmentedControlTheme.labelStyle].
  final TextStyle? labelStyle;

  /// Overrides [SegmentedControlTheme.selectedLabelStyle].
  final TextStyle? selectedLabelStyle;

  /// Overrides [SegmentedControlTheme.trackColor].
  final Color? trackColor;

  /// Overrides [SegmentedControlTheme.indicatorColor].
  final Color? indicatorColor;

  /// Overrides [SegmentedControlTheme.selectedLabelColor].
  final Color? selectedLabelColor;

  /// Overrides [SegmentedControlTheme.unselectedLabelColor].
  final Color? unselectedLabelColor;

  /// Screen-reader label for the control as a whole.
  final String? semanticLabel;

  /// The theme, with this widget's per-instance overrides applied.
  SegmentedControlTheme _theme(BuildContext context) =>
      SegmentedControlTheme.of(context).copyWith(
        height: height,
        trackPadding: padding,
        trackRadius: trackRadius,
        indicatorRadius: indicatorRadius,
        trackShape: trackShape,
        indicatorShape: indicatorShape,
        labelStyle: labelStyle,
        selectedLabelStyle: selectedLabelStyle,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        selectedLabelColor: selectedLabelColor,
        unselectedLabelColor: unselectedLabelColor,
      );

  /// Key on the sliding indicator, so host tests can find and measure it.
  static const Key indicatorKey = Key('sliding_segmented_control.indicator');

  /// Where the indicator sits along the track's main axis, from `-1` (start)
  /// to `1` (end).
  static double indicatorAlignment(int index, int count) =>
      count < 2 ? 0 : -1 + 2 * index / (count - 1);

  void _handleTap(int index) {
    if (!enabled || !segments[index].enabled || index == selectedIndex) return;
    onSegmentChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        width: double.infinity,
        height: theme.height,
        padding: theme.trackPadding,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: theme.trackColor,
          shape: theme.resolvedTrackShape,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / segments.length;
            return Stack(
              children: [
                _Indicator(
                  theme: theme,
                  duration: duration,
                  curve: curve,
                  width: segmentWidth,
                  alignment:
                      indicatorAlignment(selectedIndex, segments.length),
                ),
                Row(
                  children: [
                    for (var i = 0; i < segments.length; i++)
                      Expanded(
                        child: _SegmentTile(
                          segment: segments[i],
                          theme: theme,
                          textTheme: textTheme,
                          selected: i == selectedIndex,
                          enabled: enabled && segments[i].enabled,
                          onTap: () => _handleTap(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The pill that slides behind the selected segment.
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.theme,
    required this.duration,
    required this.curve,
    required this.width,
    required this.alignment,
  });

  final SegmentedControlTheme theme;
  final Duration duration;
  final Curve curve;
  final double width;
  final double alignment;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: AnimatedAlign(
          duration: duration,
          curve: curve,
          alignment: AlignmentDirectional(alignment, 0),
          child: SizedBox(
            key: SlidingSegmentedControl.indicatorKey,
            width: width,
            height: double.infinity,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: theme.indicatorColor,
                shape: theme.resolvedIndicatorShape,
                shadows: theme.indicatorShadows,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One tappable segment: its icon, its label, and its semantics.
class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    required this.segment,
    required this.theme,
    required this.textTheme,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Segment segment;
  final SegmentedControlTheme theme;
  final TextTheme textTheme;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = theme.colorFor(selected: selected, enabled: enabled);
    final style =
        theme.resolvedLabelStyle(textTheme, selected: selected, enabled: enabled);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (segment.icon != null) ...[
          Icon(segment.icon, size: theme.iconSize, color: color),
          SizedBox(width: theme.iconLabelSpacing),
        ],
        Flexible(
          child: Text(
            segment.label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    if (segment.tooltip != null) {
      content = Tooltip(message: segment.tooltip!, child: content);
    }

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: segment.semanticLabel ?? segment.label,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Align(child: content),
        ),
      ),
    );
  }
}
