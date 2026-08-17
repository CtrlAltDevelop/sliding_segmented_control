import 'package:material_ui/material_ui.dart';

import 'segment.dart';
import 'segmented_body_transition.dart';
import 'segmented_control_theme.dart';
import 'sliding_segmented_control.dart';

/// The default duration of the body cross-fade.
const Duration kSegmentedBodyDuration = Duration(milliseconds: 200);

/// A [SlidingSegmentedControl] stacked above the body of the selected segment,
/// which cross-fades when the selection changes.
///
/// Works either uncontrolled — it keeps the selection itself, starting at
/// [initialIndex]:
///
/// ```dart
/// SegmentedBody(
///   pages: [
///     SegmentPage.of(label: 'Open', child: OpenPositions()),
///     SegmentPage.of(label: 'Closed', child: ClosedPositions()),
///   ],
/// )
/// ```
///
/// or controlled, by passing [selectedIndex] and updating it from
/// [onSegmentChanged].
///
/// Only the selected page is built, so the others cost nothing until they are
/// picked.
class SegmentedBody extends StatefulWidget {
  const SegmentedBody({
    super.key,
    required this.pages,
    this.selectedIndex,
    this.onSegmentChanged,
    this.initialIndex = 0,
    this.enabled = true,
    this.spacing = 14,
    this.controlMargin = EdgeInsets.zero,
    this.controlPadding,
    this.controlHeight,
    this.bodyExpanded = false,
    this.bodyDuration = kSegmentedBodyDuration,
    this.bodyTransition = SegmentedBodyTransition.fade,
    this.transitionBuilder,
    this.indicatorDuration = kSegmentedControlDuration,
    this.indicatorCurve = Curves.easeInOut,
    this.semanticLabel,
  })  : assert(pages.length > 0, 'pages must not be empty'),
        assert(
          initialIndex >= 0 && initialIndex < pages.length,
          'initialIndex must be a valid index into pages',
        ),
        assert(
          selectedIndex == null ||
              (selectedIndex >= 0 && selectedIndex < pages.length),
          'selectedIndex must be a valid index into pages',
        );

  /// The segments and the body each one shows. Must not be empty.
  final List<SegmentPage> pages;

  /// The selected index. Pass it to drive the selection yourself; leave it
  /// null to let the widget keep its own.
  final int? selectedIndex;

  /// Called with the newly selected index, in both modes.
  final ValueChanged<int>? onSegmentChanged;

  /// The index selected first, when [selectedIndex] is null.
  final int initialIndex;

  /// Whether the control accepts taps.
  final bool enabled;

  /// Gap between the control and the body.
  final double spacing;

  /// Padding around the control, outside its track.
  final EdgeInsetsGeometry controlMargin;

  /// Padding inside the control's track. Falls back to the theme's
  /// [SegmentedControlTheme.trackPadding].
  final EdgeInsetsGeometry? controlPadding;

  /// Height of the control. Falls back to [SegmentedControlTheme.height].
  final double? controlHeight;

  /// Whether the body fills the remaining height. Leave it false inside a
  /// scroll view, where the height is unbounded.
  final bool bodyExpanded;

  /// How long the body takes to cross-fade.
  final Duration bodyDuration;

  /// Which of the ready-made transitions animates the body. Defaults to a
  /// cross-fade; [SegmentedBodyTransition.slide] follows the direction the
  /// selection moved in.
  ///
  /// Ignored when [transitionBuilder] is set.
  final SegmentedBodyTransition bodyTransition;

  /// A transition of your own, overriding [bodyTransition] when set.
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;

  /// How long the control's indicator takes to slide.
  final Duration indicatorDuration;

  /// The curve the control's indicator slides on.
  final Curve indicatorCurve;

  /// Screen-reader label for the control.
  final String? semanticLabel;

  @override
  State<SegmentedBody> createState() => _SegmentedBodyState();
}

class _SegmentedBodyState extends State<SegmentedBody> {
  late int _selectedIndex = widget.selectedIndex ?? widget.initialIndex;

  /// The index the body last settled on, and which way it moved to get to the
  /// current one: `1` towards the end, `-1` towards the start.
  ///
  /// Held rather than recomputed per build so that an in-flight transition
  /// keeps the direction it started with.
  ///
  /// Seeded eagerly in [initState]: a `late` initialiser would not run until
  /// the first [_recordDirection], by which time the index has already moved
  /// and the direction is lost.
  late int _lastIndex;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _lastIndex = _effectiveIndex;
  }

  /// The index to show: the host's while controlled, ours otherwise.
  int get _effectiveIndex =>
      (widget.selectedIndex ?? _selectedIndex).clamp(0, widget.pages.length - 1);

  @override
  void didUpdateWidget(SegmentedBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep our own index in range when the host swaps a shorter page list in.
    if (_selectedIndex >= widget.pages.length) {
      _selectedIndex = widget.pages.length - 1;
    }
    _recordDirection(_effectiveIndex);
  }

  /// Notes which way the body is travelling, on the way to [index].
  void _recordDirection(int index) {
    if (index == _lastIndex) return;
    _direction = index > _lastIndex ? 1 : -1;
    _lastIndex = index;
  }

  void _onSegmentChanged(int index) {
    if (widget.selectedIndex == null) {
      _recordDirection(index);
      setState(() => _selectedIndex = index);
    }
    widget.onSegmentChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final index = _effectiveIndex;
    final currentKey = ValueKey<int>(index);
    final body = AnimatedSwitcher(
      duration: widget.bodyDuration,
      transitionBuilder: widget.transitionBuilder ??
          widget.bodyTransition.builder(
            direction: _direction,
            currentKey: currentKey,
            textDirection: Directionality.of(context),
          ),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
      child: KeyedSubtree(
        key: currentKey,
        child: widget.pages[index].child,
      ),
    );

    return Column(
      spacing: widget.spacing,
      children: [
        Padding(
          padding: widget.controlMargin,
          child: SlidingSegmentedControl(
            segments: [for (final page in widget.pages) page.segment],
            selectedIndex: index,
            onSegmentChanged: _onSegmentChanged,
            enabled: widget.enabled,
            padding: widget.controlPadding,
            height: widget.controlHeight,
            duration: widget.indicatorDuration,
            curve: widget.indicatorCurve,
            semanticLabel: widget.semanticLabel,
          ),
        ),
        if (widget.bodyExpanded) Expanded(child: body) else body,
      ],
    );
  }
}
