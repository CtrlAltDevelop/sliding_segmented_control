# Changelog

## 0.1.1

- Dropped the `figma_squircle` dependency: the package now needs nothing but
  Flutter. Corners are drawn by `RoundedSuperellipseBorder`, in the framework
  since Flutter 3.32, which the engine rasterises directly.
- Corner radii are settable from the call site. `trackRadius` and
  `indicatorRadius` take any `BorderRadiusGeometry` — one radius, a different
  radius per corner, elliptical corners, or the directional
  `BorderRadiusDirectional` — on the theme or per instance.
- `trackShape` / `indicatorShape` take a whole `ShapeBorder`, also per
  instance, so a host can bring corner geometry this package does not ship —
  a `figma_squircle` squircle, for instance — and keep that dependency in its
  own pubspec.
- `cornerSmoothing`, a `figma_squircle` notion, gives way to the
  `smoothCorners` flag.
- The Flutter floor moves to 3.32.0 for `RoundedSuperellipseBorder`.

## 0.1.0

- First release.
- `SlidingSegmentedControl` — a segmented control whose selection is marked by
  a pill sliding between equally-sized segments, with per-segment icons,
  tooltips and disabled states.
- `SegmentedBody` — the control above the body of the selected segment, which
  cross-fades on change. Works controlled or uncontrolled, and builds only the
  selected page.
- `SegmentedBodyTransition` — `fade` (the default), `slide` and `scale` for the
  body change, with `transitionBuilder` still there for anything else. `slide`
  follows the direction the selection moved in, and mirrors under RTL.
- `SegmentedControlTheme`, a `ThemeExtension` covering colours, text styles,
  shapes and metrics, with `copyWith` and `lerp`. With none registered, the
  palette is derived from the ambient `ColorScheme`.
- Right-to-left is handled by positioning the indicator with
  `AlignmentDirectional`.
- Segments are exposed to screen readers as buttons carrying their selected and
  enabled state.
- README screenshots are generated from the real widgets by
  `example/test/screenshots_test.dart`.
