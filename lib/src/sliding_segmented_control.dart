import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'segment.dart';
import 'segment_sizing.dart';
import 'segmented_control_theme.dart';
import 'segmented_track.dart';

/// The default duration of the indicator slide.
const Duration kSegmentedControlDuration = Duration(milliseconds: 250);

/// A segmented control whose selection is marked by a pill that slides between
/// segments, rather than by a highlighted button.
///
/// By default the segments share the available width equally and the control
/// fills its parent horizontally; [sizing] gives each segment its own width
/// instead, in place or inside a scroll view. Colours, shapes and metrics come
/// from [SegmentedControlTheme]; per-instance overrides on the widget win over
/// it.
///
/// ```dart
/// SlidingSegmentedControl(
///   segments: const [Segment(label: 'Buy'), Segment(label: 'Sell')],
///   selectedIndex: index,
///   onSegmentChanged: (i) => setState(() => index = i),
/// )
/// ```
///
/// The selection can be tapped, dragged — press the pill and slide it, as on
/// iOS — or moved with the arrow keys once the control has focus. The
/// indicator is laid out along the text direction, so the control reads
/// correctly under [TextDirection.rtl] with no extra work.
class SlidingSegmentedControl extends StatefulWidget {
  const SlidingSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentChanged,
    this.enabled = true,
    this.sizing = SegmentSizing.equal,
    this.enableDrag = true,
    this.enableFeedback = true,
    this.autofocus = false,
    this.scrollController,
    this.duration = kSegmentedControlDuration,
    this.curve = Curves.easeInOut,
    this.height,
    this.padding,
    this.segmentPadding,
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

  /// Called with the newly selected index, whether it was tapped, dragged to
  /// or moved to with the keyboard. Not called for the already-selected
  /// segment or for a disabled one.
  final ValueChanged<int> onSegmentChanged;

  /// Whether the whole control accepts input. Disabling it dims every label.
  final bool enabled;

  /// How the segments share the control's width. Equal shares by default.
  final SegmentSizing sizing;

  /// Whether the pill can be dragged between segments.
  ///
  /// The drag starts on the pill itself, follows the pointer, and commits to
  /// the segment nearest where it is let go.
  final bool enableDrag;

  /// Whether a selection change fires haptic feedback, which it does as the
  /// pill crosses into a segment mid-drag.
  final bool enableFeedback;

  /// Whether the selected segment takes focus when the control first builds.
  final bool autofocus;

  /// Controller for the scroll view of a [SegmentSizing.scrollable] control.
  /// Ignored by the other sizing modes.
  final ScrollController? scrollController;

  /// How long the indicator takes to slide.
  final Duration duration;

  /// The curve the indicator slides on.
  final Curve curve;

  /// Overrides [SegmentedControlTheme.height].
  final double? height;

  /// Overrides [SegmentedControlTheme.trackPadding].
  final EdgeInsetsGeometry? padding;

  /// Overrides [SegmentedControlTheme.segmentPadding].
  final EdgeInsetsGeometry? segmentPadding;

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

  /// Key on the sliding indicator, so host tests can find and measure it.
  static const Key indicatorKey = Key('sliding_segmented_control.indicator');

  /// Key on the segment at [index], so host tests can find and measure it.
  static Key segmentKey(int index) =>
      ValueKey('sliding_segmented_control.segment.$index');

  /// Where the indicator sits along the track's main axis, from `-1` (start)
  /// to `1` (end), for equally-sized segments.
  static double indicatorAlignment(int index, int count) =>
      count < 2 ? 0 : -1 + 2 * index / (count - 1);

  @override
  State<SlidingSegmentedControl> createState() =>
      _SlidingSegmentedControlState();
}

class _SlidingSegmentedControlState extends State<SlidingSegmentedControl>
    with SingleTickerProviderStateMixin {
  /// Where the indicator is, as a continuous index. Animated on a selection
  /// change, and set outright while the pill is being dragged.
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );

  /// Focus nodes and keys, one per segment, grown and shrunk with [segments].
  final List<FocusNode> _nodes = [];
  final List<GlobalKey> _keys = [];

  int? _hovered;
  int? _focused;

  /// The pill's position when the drag began, and the pointer's, so the pill
  /// travels with the pointer rather than jumping under it.
  double? _dragStartPosition;
  double? _dragStartPointer;
  int _dragIndex = 0;

  final GlobalKey _trackKey = GlobalKey();

  RenderSegmentedTrack? get _track =>
      _trackKey.currentContext?.findRenderObject() as RenderSegmentedTrack?;

  bool get _dragging => _dragStartPosition != null;

  @override
  void initState() {
    super.initState();
    _syncSegments();
  }

  @override
  void didUpdateWidget(SlidingSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSegments();
    if (widget.selectedIndex != oldWidget.selectedIndex && !_dragging) {
      _animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    _position.dispose();
    super.dispose();
  }

  /// Keeps one focus node and one key per segment.
  void _syncSegments() {
    while (_nodes.length < widget.segments.length) {
      _nodes.add(FocusNode(debugLabel: 'Segment ${_nodes.length}'));
      _keys.add(GlobalKey());
    }
    while (_nodes.length > widget.segments.length) {
      _nodes.removeLast().dispose();
      _keys.removeLast();
    }
  }

  void _animateTo(int index) {
    _position.animateTo(
      index.toDouble(),
      duration: widget.duration,
      curve: widget.curve,
    );
  }

  bool _selectable(int index) =>
      widget.enabled && widget.segments[index].enabled;

  /// Reports [index] as the new selection, and moves the indicator there.
  ///
  /// The host owns the selection, so the indicator is walked to [index]
  /// optimistically and then corrected once the frame has settled, in case
  /// the host kept the old index.
  void _select(int index, {bool feedback = false}) {
    if (!_selectable(index) || index == widget.selectedIndex) {
      _animateTo(widget.selectedIndex);
      return;
    }
    if (feedback && widget.enableFeedback) HapticFeedback.selectionClick();
    _animateTo(index);
    widget.onSegmentChanged(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dragging && widget.selectedIndex != index) {
        _animateTo(widget.selectedIndex);
      }
    });
  }

  // --- Dragging ------------------------------------------------------------

  void _onDragStart(DragStartDetails details) {
    final track = _track;
    if (track == null || !widget.enableDrag || !widget.enabled) return;
    final x = track.globalToLocal(details.globalPosition).dx;
    // Only the pill is draggable; a press anywhere else is a tap.
    if (track.indexForOffset(x) != widget.selectedIndex) return;
    setState(() {
      _dragStartPosition = _position.value;
      _dragStartPointer = x;
      _dragIndex = widget.selectedIndex;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final track = _track;
    if (track == null || !_dragging) return;
    final x = track.globalToLocal(details.globalPosition).dx;
    final centre = track.centerForPosition(_dragStartPosition!) +
        (x - _dragStartPointer!);
    final position = track
        .positionForCenter(centre)
        .clamp(0.0, (widget.segments.length - 1).toDouble());
    _position.value = position;

    final index = position.round();
    if (index != _dragIndex) {
      _dragIndex = index;
      if (widget.enableFeedback && _selectable(index)) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    final index = _position.value.round();
    setState(() {
      _dragStartPosition = null;
      _dragStartPointer = null;
    });
    _select(index);
  }

  // --- Keyboard ------------------------------------------------------------

  /// Selects the next enabled segment [delta] steps away, wrapping at neither
  /// end, and moves focus with it.
  void _move(int delta) {
    if (Directionality.of(context) == TextDirection.rtl) delta = -delta;
    for (var i = widget.selectedIndex + delta;
        i >= 0 && i < widget.segments.length;
        i += delta) {
      if (_selectable(i)) {
        _nodes[i].requestFocus();
        _select(i, feedback: true);
        return;
      }
    }
  }

  /// Selects the first enabled segment from the [start] end.
  void _moveToEnd({required bool start}) {
    final indices = List.generate(widget.segments.length, (i) => i);
    for (final i in start ? indices : indices.reversed) {
      if (_selectable(i)) {
        _nodes[i].requestFocus();
        _select(i, feedback: true);
        return;
      }
    }
  }

  /// The index [_ensureVisible] last scrolled to, so that a rebuild for any
  /// other reason does not fight the reader's own scrolling.
  int? _scrolledTo;

  /// Scrolls the selected segment into view, for a scrollable track.
  void _ensureVisible(int index) {
    if (widget.sizing != SegmentSizing.scrollable || index == _scrolledTo) {
      return;
    }
    final context = _keys[index].currentContext;
    if (context == null) return;
    _scrolledTo = index;
    Scrollable.ensureVisible(
      context,
      duration: widget.duration,
      curve: widget.curve,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      alignment: 0.5,
    );
  }

  /// The theme, with this widget's per-instance overrides applied.
  SegmentedControlTheme _theme(BuildContext context) =>
      SegmentedControlTheme.of(context).copyWith(
        height: widget.height,
        trackPadding: widget.padding,
        segmentPadding: widget.segmentPadding,
        trackRadius: widget.trackRadius,
        indicatorRadius: widget.indicatorRadius,
        trackShape: widget.trackShape,
        indicatorShape: widget.indicatorShape,
        labelStyle: widget.labelStyle,
        selectedLabelStyle: widget.selectedLabelStyle,
        trackColor: widget.trackColor,
        indicatorColor: widget.indicatorColor,
        selectedLabelColor: widget.selectedLabelColor,
        unselectedLabelColor: widget.unselectedLabelColor,
      );

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final textTheme = Theme.of(context).textTheme;
    final textDirection = Directionality.of(context);

    if (widget.sizing == SegmentSizing.scrollable &&
        widget.selectedIndex != _scrolledTo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureVisible(widget.selectedIndex);
      });
    }

    final indicator = RepaintBoundary(
      child: SizedBox(
        key: SlidingSegmentedControl.indicatorKey,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: theme.indicatorColor,
            shape: theme.resolvedIndicatorShape,
            shadows: theme.indicatorShadows,
          ),
        ),
      ),
    );

    // The control is one tab stop, like a radio group: Tab reaches the
    // selected segment, and the arrow keys move from there.
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != widget.selectedIndex;
    }

    final segments = [
      for (var i = 0; i < widget.segments.length; i++)
        _SegmentTile(
          key: _keys[i],
          index: i,
          segment: widget.segments[i],
          theme: theme,
          textTheme: textTheme,
          focusNode: _nodes[i],
          selected: i == widget.selectedIndex,
          enabled: _selectable(i),
          hovered: _hovered == i,
          focused: _focused == i,
          autofocus: widget.autofocus && i == widget.selectedIndex,
          onHover: (on) => setState(() => _hovered = on ? i : null),
          onFocus: (on) => setState(() => _focused = on ? i : null),
          onTap: () => _select(i),
          onMove: _move,
          onMoveToEnd: _moveToEnd,
        ),
    ];

    Widget track = AnimatedBuilder(
      animation: _position,
      builder: (context, _) => SegmentedTrack(
        key: _trackKey,
        position: _position.value,
        sizing: widget.sizing,
        textDirection: textDirection,
        indicator: indicator,
        segments: segments,
      ),
    );

    if (widget.sizing == SegmentSizing.scrollable) {
      track = SingleChildScrollView(
        controller: widget.scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: track,
      );
    }

    Widget control = Container(
      width: widget.sizing == SegmentSizing.intrinsic ? null : double.infinity,
      height: theme.height,
      padding: theme.trackPadding,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: theme.trackColor,
        shape: theme.resolvedTrackShape,
      ),
      child: track,
    );

    if (widget.enableDrag && widget.enabled) {
      control = GestureDetector(
        // The pill has to track the pointer from where it first touched
        // down, slop included, or it lags the finger by 18 logical pixels.
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: control,
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      container: true,
      child: control,
    );
  }
}

/// Moves the selection one segment towards the start or the end.
class _MoveSelectionIntent extends Intent {
  const _MoveSelectionIntent(this.delta);
  final int delta;
}

/// Moves the selection to the first or last segment.
class _MoveToEndIntent extends Intent {
  const _MoveToEndIntent({required this.start});
  final bool start;
}

/// One segment: its content, its interaction states, and its semantics.
class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    super.key,
    required this.index,
    required this.segment,
    required this.theme,
    required this.textTheme,
    required this.focusNode,
    required this.selected,
    required this.enabled,
    required this.hovered,
    required this.focused,
    required this.autofocus,
    required this.onHover,
    required this.onFocus,
    required this.onTap,
    required this.onMove,
    required this.onMoveToEnd,
  });

  final int index;
  final Segment segment;
  final SegmentedControlTheme theme;
  final TextTheme textTheme;
  final FocusNode focusNode;
  final bool selected;
  final bool enabled;
  final bool hovered;
  final bool focused;
  final bool autofocus;
  final ValueChanged<bool> onHover;
  final ValueChanged<bool> onFocus;
  final VoidCallback onTap;
  final ValueChanged<int> onMove;
  final void Function({required bool start}) onMoveToEnd;

  static const Map<ShortcutActivator, Intent> _shortcuts = {
    SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveSelectionIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowRight): _MoveSelectionIntent(1),
    SingleActivator(LogicalKeyboardKey.home): _MoveToEndIntent(start: true),
    SingleActivator(LogicalKeyboardKey.end): _MoveToEndIntent(start: false),
  };

  @override
  Widget build(BuildContext context) {
    final color = theme.colorFor(selected: selected, enabled: enabled);
    final style = theme.resolvedLabelStyle(
      textTheme,
      selected: selected,
      enabled: enabled,
    );

    Widget content = segment.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (segment.icon != null) ...[
              Icon(segment.icon, size: theme.iconSize, color: color),
              SizedBox(width: theme.iconLabelSpacing),
            ] else if (segment.iconWidget != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: color, size: theme.iconSize),
                child: segment.iconWidget!,
              ),
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

    if (segment.badge != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: content),
          SizedBox(width: theme.iconLabelSpacing),
          segment.badge!,
        ],
      );
    }

    content = Padding(
      padding: theme.segmentPadding,
      child: Align(widthFactor: 1, heightFactor: 1, child: content),
    );

    // The overlay and the focus ring sit over the indicator but under the
    // label, so a focused segment reads without washing its own text out.
    final overlay = theme.overlayFor(hovered: hovered, focused: focused);
    if (overlay != null || focused) {
      content = DecoratedBox(
        decoration: ShapeDecoration(
          color: overlay,
          shape: focused && theme.focusOutlineWidth > 0
              ? theme.resolvedFocusOutlineShape
              : theme.resolvedIndicatorShape,
        ),
        child: content,
      );
    }

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
      child: FocusableActionDetector(
        enabled: enabled,
        autofocus: autofocus,
        focusNode: focusNode,
        descendantsAreFocusable: false,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: onHover,
        onShowFocusHighlight: onFocus,
        shortcuts: _shortcuts,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
          _MoveSelectionIntent: CallbackAction<_MoveSelectionIntent>(
            onInvoke: (intent) {
              onMove(intent.delta);
              return null;
            },
          ),
          _MoveToEndIntent: CallbackAction<_MoveToEndIntent>(
            onInvoke: (intent) {
              onMoveToEnd(start: intent.start);
              return null;
            },
          ),
        },
        child: GestureDetector(
          key: SlidingSegmentedControl.segmentKey(index),
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: content,
        ),
      ),
    );
  }
}
