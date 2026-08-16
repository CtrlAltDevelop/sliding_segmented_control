import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

/// Everything a [SlidingSegmentedControl] needs to paint itself.
///
/// Register it as a [ThemeExtension] so the control follows your app's light
/// and dark themes:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(extensions: const [SegmentedControlTheme.light]),
///   darkTheme: ThemeData(extensions: const [SegmentedControlTheme.dark]),
/// );
/// ```
///
/// When no extension is registered, [SegmentedControlTheme.of] derives a
/// usable palette from the ambient [ColorScheme], so the control looks
/// reasonable with no setup at all.
@immutable
class SegmentedControlTheme extends ThemeExtension<SegmentedControlTheme> {
  const SegmentedControlTheme({
    required this.trackColor,
    required this.borderColor,
    required this.indicatorColor,
    required this.selectedLabelColor,
    required this.unselectedLabelColor,
    this.disabledLabelColor,
    this.labelStyle,
    this.selectedLabelStyle,
    this.fontFamily,
    this.borderWidth = 1,
    this.trackRadius = const BorderRadius.all(Radius.circular(8)),
    this.indicatorRadius = const BorderRadius.all(Radius.circular(4)),
    this.trackShape,
    this.indicatorShape,
    this.cornerSmoothing = 1,
    this.trackPadding = const EdgeInsets.all(4),
    this.height = 44,
    this.iconSize = 14,
    this.iconLabelSpacing = 4,
    this.indicatorShadows = const <BoxShadow>[],
  });

  /// Background of the track behind the segments.
  final Color trackColor;

  /// Colour of the track's outline. Set [borderWidth] to `0` to drop it.
  final Color borderColor;

  /// Fill of the sliding indicator (the "pill") behind the selected segment.
  final Color indicatorColor;

  /// Label and icon colour of the selected segment. Must contrast with
  /// [indicatorColor].
  final Color selectedLabelColor;

  /// Label and icon colour of every other segment.
  final Color unselectedLabelColor;

  /// Label colour of disabled segments. Defaults to [unselectedLabelColor] at
  /// 38% opacity.
  final Color? disabledLabelColor;

  /// Style of unselected labels. When null the ambient `bodyMedium` is used.
  ///
  /// Anything it sets wins: a [labelStyle] with its own `color` or
  /// `fontFamily` is used as given rather than being overwritten.
  final TextStyle? labelStyle;

  /// Style of the selected label. Falls back to [labelStyle].
  final TextStyle? selectedLabelStyle;

  /// Font family for every label, for hosts that only want to swap the
  /// typeface. A family set on one of the styles above wins over this.
  final String? fontFamily;

  /// Width of the track outline. `0` removes it.
  final double borderWidth;

  /// Corner radii of the track. Ignored when [trackShape] is set.
  final BorderRadius trackRadius;

  /// Corner radii of the indicator. Ignored when [indicatorShape] is set.
  final BorderRadius indicatorRadius;

  /// Shape of the track. Overrides [trackRadius] and [borderColor] when set;
  /// defaults to an outlined squircle of [trackRadius].
  final ShapeBorder? trackShape;

  /// Shape of the indicator. Overrides [indicatorRadius] when set; defaults to
  /// a squircle of [indicatorRadius].
  final ShapeBorder? indicatorShape;

  /// Corner smoothing of the default squircle shapes, from `0` (a plain
  /// rounded rectangle) to `1` (a full iOS-style squircle).
  final double cornerSmoothing;

  /// Inset between the track edge and the segments.
  final EdgeInsetsGeometry trackPadding;

  /// Height of the whole control, track padding included.
  final double height;

  /// Size of a segment's [Segment.icon].
  final double iconSize;

  /// Gap between a segment's icon and its label.
  final double iconLabelSpacing;

  /// Shadows cast by the indicator. Empty by default.
  final List<BoxShadow> indicatorShadows;

  /// The registered [SegmentedControlTheme], or one derived from the ambient
  /// [ColorScheme] when the host has not registered an extension.
  static SegmentedControlTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<SegmentedControlTheme>() ?? fromScheme(theme.colorScheme);
  }

  /// A palette derived from [scheme]: a tinted indicator on a surface track.
  static SegmentedControlTheme fromScheme(ColorScheme scheme) =>
      SegmentedControlTheme(
        trackColor: scheme.surfaceContainerLow,
        borderColor: scheme.outlineVariant,
        indicatorColor: scheme.primaryContainer,
        selectedLabelColor: scheme.onPrimaryContainer,
        unselectedLabelColor: scheme.onSurfaceVariant,
      );

  /// The track shape, defaulting to an outlined squircle of [trackRadius].
  ShapeBorder get resolvedTrackShape =>
      trackShape ??
      SmoothRectangleBorder(
        side: borderWidth > 0
            ? BorderSide(width: borderWidth, color: borderColor)
            : BorderSide.none,
        borderRadius: smooth(trackRadius, cornerSmoothing),
      );

  /// The indicator shape, defaulting to a squircle of [indicatorRadius].
  ShapeBorder get resolvedIndicatorShape =>
      indicatorShape ??
      SmoothRectangleBorder(
        borderRadius: smooth(indicatorRadius, cornerSmoothing),
      );

  /// Squircles the corners of [radius] — what gives the track and indicator
  /// their smoothed, non-circular corners.
  static SmoothBorderRadius smooth(BorderRadius radius, double smoothing) =>
      SmoothBorderRadius.only(
        topLeft: SmoothRadius(
          cornerRadius: radius.topLeft.x,
          cornerSmoothing: smoothing,
        ),
        topRight: SmoothRadius(
          cornerRadius: radius.topRight.x,
          cornerSmoothing: smoothing,
        ),
        bottomLeft: SmoothRadius(
          cornerRadius: radius.bottomLeft.x,
          cornerSmoothing: smoothing,
        ),
        bottomRight: SmoothRadius(
          cornerRadius: radius.bottomRight.x,
          cornerSmoothing: smoothing,
        ),
      );

  /// The style for a segment's label, with this theme's colour and family
  /// filled in wherever the host left them unset.
  TextStyle resolvedLabelStyle(
    TextTheme textTheme, {
    required bool selected,
    required bool enabled,
  }) {
    final override = selected ? (selectedLabelStyle ?? labelStyle) : labelStyle;
    final base = override ?? textTheme.bodyMedium ?? const TextStyle();
    return base.copyWith(
      color: override?.color ?? colorFor(selected: selected, enabled: enabled),
      fontFamily: override?.fontFamily ?? fontFamily ?? base.fontFamily,
    );
  }

  /// The label and icon colour for a segment in the given state.
  Color colorFor({required bool selected, required bool enabled}) {
    if (!enabled) {
      return disabledLabelColor ?? unselectedLabelColor.withValues(alpha: 0.38);
    }
    return selected ? selectedLabelColor : unselectedLabelColor;
  }

  @override
  SegmentedControlTheme copyWith({
    Color? trackColor,
    Color? borderColor,
    Color? indicatorColor,
    Color? selectedLabelColor,
    Color? unselectedLabelColor,
    Color? disabledLabelColor,
    TextStyle? labelStyle,
    TextStyle? selectedLabelStyle,
    String? fontFamily,
    double? borderWidth,
    BorderRadius? trackRadius,
    BorderRadius? indicatorRadius,
    ShapeBorder? trackShape,
    ShapeBorder? indicatorShape,
    double? cornerSmoothing,
    EdgeInsetsGeometry? trackPadding,
    double? height,
    double? iconSize,
    double? iconLabelSpacing,
    List<BoxShadow>? indicatorShadows,
  }) =>
      SegmentedControlTheme(
        trackColor: trackColor ?? this.trackColor,
        borderColor: borderColor ?? this.borderColor,
        indicatorColor: indicatorColor ?? this.indicatorColor,
        selectedLabelColor: selectedLabelColor ?? this.selectedLabelColor,
        unselectedLabelColor: unselectedLabelColor ?? this.unselectedLabelColor,
        disabledLabelColor: disabledLabelColor ?? this.disabledLabelColor,
        labelStyle: labelStyle ?? this.labelStyle,
        selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
        fontFamily: fontFamily ?? this.fontFamily,
        borderWidth: borderWidth ?? this.borderWidth,
        trackRadius: trackRadius ?? this.trackRadius,
        indicatorRadius: indicatorRadius ?? this.indicatorRadius,
        trackShape: trackShape ?? this.trackShape,
        indicatorShape: indicatorShape ?? this.indicatorShape,
        cornerSmoothing: cornerSmoothing ?? this.cornerSmoothing,
        trackPadding: trackPadding ?? this.trackPadding,
        height: height ?? this.height,
        iconSize: iconSize ?? this.iconSize,
        iconLabelSpacing: iconLabelSpacing ?? this.iconLabelSpacing,
        indicatorShadows: indicatorShadows ?? this.indicatorShadows,
      );

  @override
  SegmentedControlTheme lerp(SegmentedControlTheme? other, double t) {
    if (other == null) return this;
    return SegmentedControlTheme(
      trackColor: Color.lerp(trackColor, other.trackColor, t) ?? trackColor,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      indicatorColor:
          Color.lerp(indicatorColor, other.indicatorColor, t) ?? indicatorColor,
      selectedLabelColor:
          Color.lerp(selectedLabelColor, other.selectedLabelColor, t) ??
              selectedLabelColor,
      unselectedLabelColor:
          Color.lerp(unselectedLabelColor, other.unselectedLabelColor, t) ??
              unselectedLabelColor,
      disabledLabelColor:
          Color.lerp(disabledLabelColor, other.disabledLabelColor, t),
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      selectedLabelStyle:
          TextStyle.lerp(selectedLabelStyle, other.selectedLabelStyle, t),
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t),
      trackRadius:
          BorderRadius.lerp(trackRadius, other.trackRadius, t) ?? trackRadius,
      indicatorRadius:
          BorderRadius.lerp(indicatorRadius, other.indicatorRadius, t) ??
              indicatorRadius,
      trackShape: t < 0.5 ? trackShape : other.trackShape,
      indicatorShape: t < 0.5 ? indicatorShape : other.indicatorShape,
      cornerSmoothing: lerpDouble(cornerSmoothing, other.cornerSmoothing, t),
      trackPadding:
          EdgeInsetsGeometry.lerp(trackPadding, other.trackPadding, t) ??
              trackPadding,
      height: lerpDouble(height, other.height, t),
      iconSize: lerpDouble(iconSize, other.iconSize, t),
      iconLabelSpacing:
          lerpDouble(iconLabelSpacing, other.iconLabelSpacing, t),
      indicatorShadows:
          BoxShadow.lerpList(indicatorShadows, other.indicatorShadows, t) ??
              indicatorShadows,
    );
  }

  /// [ui.lerpDouble] without the nullable return, since both ends are set.
  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
