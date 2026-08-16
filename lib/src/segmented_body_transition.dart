import 'package:flutter/material.dart';

/// How [SegmentedBody] animates from one body to the next.
///
/// Each of these is a ready-made [AnimatedSwitcherTransitionBuilder]; pass
/// `SegmentedBody.transitionBuilder` instead to write your own.
enum SegmentedBodyTransition {
  /// The outgoing body fades out as the incoming one fades in. The default,
  /// and the cheapest.
  fade,

  /// The incoming body slides in from the side the selection moved towards
  /// while the outgoing one leaves the other way, fading across.
  ///
  /// The direction follows the selection: picking a later segment slides the
  /// body in from the end side, picking an earlier one from the start side.
  /// Under [TextDirection.rtl] both are mirrored.
  slide,

  /// The incoming body grows into place as the outgoing one shrinks away,
  /// fading across. Direction-neutral.
  scale;

  /// How far the body travels, as a fraction of its width, for [slide].
  static const double slideExtent = 0.08;

  /// How much the body shrinks by, for [scale].
  static const double scaleExtent = 0.04;

  /// The builder for this transition.
  ///
  /// [direction] is `1` when the selection moved towards the end and `-1` when
  /// it moved towards the start; it is only read by [slide]. [currentKey]
  /// identifies the incoming child, so the outgoing one can be sent the other
  /// way. [textDirection] mirrors [slide] under right-to-left.
  AnimatedSwitcherTransitionBuilder builder({
    required int direction,
    required Key currentKey,
    required TextDirection textDirection,
  }) {
    switch (this) {
      case SegmentedBodyTransition.fade:
        return AnimatedSwitcher.defaultTransitionBuilder;

      case SegmentedBodyTransition.slide:
        return (child, animation) {
          // The outgoing child runs its animation in reverse, from 1 to 0, so
          // it walks from `end` back to `begin` — put its `begin` on the far
          // side and the two bodies travel the same way across the screen.
          final incoming = child.key == currentKey;
          final dx = slideExtent * direction * (incoming ? 1 : -1);
          return SlideTransition(
            textDirection: textDirection,
            position: animation.drive(
              Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        };

      case SegmentedBodyTransition.scale:
        return (child, animation) => ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 1 - scaleExtent, end: 1)
                    .chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
    }
  }
}
