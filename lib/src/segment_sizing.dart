/// How a [SlidingSegmentedControl] divides its width between segments.
enum SegmentSizing {
  /// Every segment is the same width, and the control fills its parent
  /// horizontally. The default, and what a two- or three-way toggle wants.
  equal,

  /// Each segment is as wide as its own content, and the control shrink-wraps
  /// them. Long labels stay readable next to short ones.
  ///
  /// Segments are scaled down proportionally if their content does not fit the
  /// width on offer; use [scrollable] to let them overflow into a scroll view
  /// instead.
  intrinsic,

  /// Each segment is as wide as its content, laid out inside a horizontal
  /// scroll view that keeps the selected segment in view.
  ///
  /// For more segments than fit on screen, where [intrinsic] would squeeze
  /// them all together.
  scrollable;

  /// Whether segments are sized by their content rather than by the track.
  bool get isContentSized => this != SegmentSizing.equal;
}
