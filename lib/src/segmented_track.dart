import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'segment_sizing.dart';

/// Lays the segments out across the track and places the indicator behind
/// whichever one — or whichever point between two of them — [position] names.
///
/// The first child is the indicator; the rest are the segments, in logical
/// order. Sizing follows [sizing]: equal shares of the track, or each
/// segment's own width.
///
/// Layout has to know every segment's width before it can place the
/// indicator, which a [Stack] of independently-positioned children cannot do
/// and a [MultiChildLayoutDelegate] cannot size itself from. Hence a render
/// object: one pass measures the segments, sizes the track from them, and
/// interpolates the indicator's rect between the two segments [position] sits
/// between.
class SegmentedTrack extends MultiChildRenderObjectWidget {
  SegmentedTrack({
    super.key,
    required this.position,
    required this.sizing,
    required this.textDirection,
    required Widget indicator,
    required List<Widget> segments,
  }) : super(children: [indicator, ...segments]);

  /// Where the indicator sits, as a continuous index into the segments: `1.0`
  /// is centred on the second segment, `1.5` halfway to the third.
  final double position;

  /// How the segments share the width.
  final SegmentSizing sizing;

  /// Which way the segments run.
  final TextDirection textDirection;

  @override
  RenderSegmentedTrack createRenderObject(BuildContext context) =>
      RenderSegmentedTrack(
        position: position,
        sizing: sizing,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSegmentedTrack renderObject,
  ) {
    renderObject
      ..position = position
      ..sizing = sizing
      ..textDirection = textDirection;
  }
}

/// Parent data for the track's children: just where each one was placed.
class SegmentedTrackParentData extends ContainerBoxParentData<RenderBox> {}

/// The render object behind [SegmentedTrack].
class RenderSegmentedTrack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, SegmentedTrackParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, SegmentedTrackParentData> {
  RenderSegmentedTrack({
    required double position,
    required SegmentSizing sizing,
    required TextDirection textDirection,
  })  // Named parameters cannot be private, so these cannot be initialising
      // formals.
      // ignore: prefer_initializing_formals
      : _position = position,
        // ignore: prefer_initializing_formals
        _sizing = sizing,
        // ignore: prefer_initializing_formals
        _textDirection = textDirection;

  double _position;
  double get position => _position;
  set position(double value) {
    if (_position == value) return;
    _position = value;
    markNeedsLayout();
  }

  SegmentSizing _sizing;
  SegmentSizing get sizing => _sizing;
  set sizing(SegmentSizing value) {
    if (_sizing == value) return;
    _sizing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// The visual left edge of each segment, in this box's coordinates. Filled
  /// in by layout, and read by the drag handler to turn a pointer position
  /// into an index.
  List<double> get segmentLefts => List.unmodifiable(_lefts);
  final List<double> _lefts = [];

  /// The width of each segment, in the same order as [segmentLefts].
  List<double> get segmentWidths => List.unmodifiable(_widths);
  final List<double> _widths = [];

  /// How many segments the track holds — every child but the indicator.
  int get segmentCount => math.max(childCount - 1, 0);

  bool get _rtl => textDirection == TextDirection.rtl;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! SegmentedTrackParentData) {
      child.parentData = SegmentedTrackParentData();
    }
  }

  /// The segments, in logical order. The indicator is the first child.
  Iterable<RenderBox> get _segments sync* {
    var child = firstChild == null ? null : childAfter(firstChild!);
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth(height, min: true);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth(height, min: false);

  double _intrinsicWidth(double height, {required bool min}) {
    var total = 0.0;
    var widest = 0.0;
    for (final segment in _segments) {
      final width = min
          ? segment.getMinIntrinsicWidth(height)
          : segment.getMaxIntrinsicWidth(height);
      total += width;
      widest = math.max(widest, width);
    }
    // Equal segments are all as wide as the widest one needs to be.
    return sizing == SegmentSizing.equal ? widest * segmentCount : total;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight(width);

  double _intrinsicHeight(double width) {
    var tallest = 0.0;
    for (final segment in _segments) {
      tallest = math.max(tallest, segment.getMaxIntrinsicHeight(width));
    }
    return tallest;
  }

  @override
  void performLayout() {
    _lefts.clear();
    _widths.clear();
    if (segmentCount == 0) {
      size = constraints.smallest;
      return;
    }

    final height = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : _intrinsicHeight(constraints.maxWidth);

    final widths = <double>[];
    if (sizing == SegmentSizing.equal) {
      // An unbounded width has no equal share to hand out, so fall back to
      // the widest segment's intrinsic width.
      final total = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : _intrinsicWidth(height, min: false);
      final each = total / segmentCount;
      for (final segment in _segments) {
        segment.layout(
          BoxConstraints.tightFor(width: each, height: height),
          parentUsesSize: true,
        );
        widths.add(each);
      }
    } else {
      for (final segment in _segments) {
        segment.layout(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
            minHeight: height,
            maxHeight: height,
          ),
          parentUsesSize: true,
        );
        widths.add(segment.size.width);
      }
      final total = widths.fold(0.0, (sum, width) => sum + width);
      // Content that does not fit is squeezed proportionally rather than
      // overflowing — a scrollable track is given unbounded width, so it
      // never reaches here.
      if (constraints.hasBoundedWidth && total > constraints.maxWidth) {
        final scale = constraints.maxWidth / total;
        var i = 0;
        for (final segment in _segments) {
          widths[i] *= scale;
          segment.layout(
            BoxConstraints.tightFor(width: widths[i], height: height),
            parentUsesSize: true,
          );
          i++;
        }
      }
    }

    final width = constraints.constrainWidth(
      widths.fold(0.0, (sum, each) => sum + each),
    );
    size = Size(width, constraints.constrainHeight(height));

    // Place each segment, mapping logical order onto visual position so that
    // a right-to-left track runs the other way.
    var x = 0.0;
    var i = 0;
    for (final segment in _segments) {
      final left = _rtl ? size.width - x - widths[i] : x;
      (segment.parentData! as SegmentedTrackParentData).offset =
          Offset(left, 0);
      _lefts.add(left);
      _widths.add(widths[i]);
      x += widths[i];
      i++;
    }

    _layoutIndicator(height);
  }

  /// Sizes and places the indicator on the rect [position] names, which for a
  /// fractional position is the lerp of the two segments it sits between.
  void _layoutIndicator(double height) {
    final indicator = firstChild;
    if (indicator == null) return;

    final clamped = position.clamp(0, segmentCount - 1).toDouble();
    final low = clamped.floor();
    final high = math.min(low + 1, segmentCount - 1);
    final t = clamped - low;

    final width = _lerp(_widths[low], _widths[high], t);
    final left = _lerp(_lefts[low], _lefts[high], t);

    indicator.layout(BoxConstraints.tightFor(width: width, height: height));
    (indicator.parentData! as SegmentedTrackParentData).offset =
        Offset(left, 0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// The visual centre of the segment — or point between segments — at
  /// [position].
  double centerForPosition(double position) {
    if (_widths.isEmpty) return 0;
    final clamped = position.clamp(0, segmentCount - 1).toDouble();
    final low = clamped.floor();
    final high = math.min(low + 1, segmentCount - 1);
    final t = clamped - low;
    return _lerp(
      _lefts[low] + _widths[low] / 2,
      _lefts[high] + _widths[high] / 2,
      t,
    );
  }

  /// The continuous position whose centre falls on [x], the inverse of
  /// [centerForPosition]. Used to make the indicator follow a drag.
  double positionForCenter(double x) {
    if (segmentCount < 2) return 0;
    final centers = [
      for (var i = 0; i < segmentCount; i++) _lefts[i] + _widths[i] / 2,
    ];
    // Centres ascend left-to-right and descend right-to-left; bracketing by
    // sign works either way round.
    for (var i = 0; i < segmentCount - 1; i++) {
      final a = centers[i];
      final b = centers[i + 1];
      if ((x - a) * (x - b) <= 0 && a != b) return i + (x - a) / (b - a);
    }
    return (x - centers.first).abs() <= (x - centers.last).abs()
        ? 0
        : segmentCount - 1;
  }

  /// The index of the segment under [x], for a tap or the end of a drag.
  int indexForOffset(double x) => positionForCenter(x).round().clamp(
        0,
        math.max(segmentCount - 1, 0),
      );

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
