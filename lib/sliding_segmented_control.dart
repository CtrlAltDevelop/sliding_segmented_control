/// A segmented control whose selection is marked by a pill that slides between
/// segments, plus a variant that cross-fades a body underneath it.
///
/// ```dart
/// SegmentedBody(
///   pages: [
///     SegmentPage.of(label: 'Open', child: OpenPositions()),
///     SegmentPage.of(label: 'Closed', child: ClosedPositions()),
///   ],
/// );
/// ```
///
/// Colours, shapes and metrics come from [SegmentedControlTheme], registered
/// as a `ThemeExtension`; with none registered the control derives a palette
/// from the ambient `ColorScheme`.
library;

export 'src/segment.dart';
export 'src/segment_sizing.dart';
export 'src/segmented_body.dart';
export 'src/segmented_body_transition.dart';
export 'src/segmented_control_theme.dart';
export 'src/sliding_segmented_control.dart';
