import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_segmented_control/sliding_segmented_control.dart';

void main() {
  Widget host(
    Widget child, {
    TextDirection direction = TextDirection.ltr,
    SegmentedControlTheme? theme,
    double? width = 300,
  }) =>
      MaterialApp(
        theme: ThemeData(extensions: theme == null ? const [] : [theme]),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Center(
              child: width == null ? child : SizedBox(width: width, child: child),
            ),
          ),
        ),
      );

  final indicator = find.byKey(SlidingSegmentedControl.indicatorKey);
  final indicatorBox = find.descendant(
    of: indicator,
    matching: find.byType(DecoratedBox),
  );

  const segments = [
    Segment(label: 'One'),
    Segment(label: 'Two'),
    Segment(label: 'Three'),
  ];

  group('SlidingSegmentedControl', () {
    testWidgets('renders every label', (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        onSegmentChanged: (_) {},
      )));

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('reports the tapped index', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        onSegmentChanged: taps.add,
      )));

      await tester.tap(find.text('Three'));
      expect(taps, [2]);
    });

    testWidgets('ignores a tap on the selected segment', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 1,
        onSegmentChanged: taps.add,
      )));

      await tester.tap(find.text('Two'));
      expect(taps, isEmpty);
    });

    testWidgets('ignores a tap on a disabled segment', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: const [
          Segment(label: 'On'),
          Segment(label: 'Off', enabled: false),
        ],
        selectedIndex: 0,
        onSegmentChanged: taps.add,
      )));

      await tester.tap(find.text('Off'));
      expect(taps, isEmpty);
    });

    testWidgets('ignores taps while the control is disabled', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        enabled: false,
        onSegmentChanged: taps.add,
      )));

      await tester.tap(find.text('Two'));
      expect(taps, isEmpty);
    });

    testWidgets('the indicator sits over the selected segment',
        (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 2,
        onSegmentChanged: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(indicator).center.dx,
        closeTo(tester.getRect(find.text('Three')).center.dx, 1),
      );
    });

    testWidgets('the indicator starts from the right under RTL',
        (tester) async {
      await tester.pumpWidget(host(
        SlidingSegmentedControl(
          segments: segments,
          selectedIndex: 0,
          onSegmentChanged: (_) {},
        ),
        direction: TextDirection.rtl,
      ));
      await tester.pumpAndSettle();

      final pill = tester.getRect(indicator);
      final control = tester.getRect(find.byType(SlidingSegmentedControl));
      expect(
        pill.center.dx,
        closeTo(tester.getRect(find.text('One')).center.dx, 1),
      );
      // First segment, so under RTL it must sit in the track's right half.
      expect(pill.center.dx, greaterThan(control.center.dx));
    });

    testWidgets('exposes each segment as a selectable button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 1,
        onSegmentChanged: (_) {},
      )));

      expect(
        tester.getSemantics(find.text('Two')),
        matchesSemantics(
          label: 'Two',
          isButton: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasSelectedState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('per-instance colours win over the theme', (tester) async {
      await tester.pumpWidget(host(
        SlidingSegmentedControl(
          segments: segments,
          selectedIndex: 0,
          onSegmentChanged: (_) {},
          indicatorColor: const Color(0xFF00FF00),
        ),
        theme: SegmentedControlTheme.fromScheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        ),
      ));

      final decorated = tester.widget<DecoratedBox>(indicatorBox);
      final shape = decorated.decoration as ShapeDecoration;
      expect(shape.color, const Color(0xFF00FF00));
    });

    test('the indicator spans the track end to end', () {
      expect(SlidingSegmentedControl.indicatorAlignment(0, 1), 0);
      expect(SlidingSegmentedControl.indicatorAlignment(0, 3), -1);
      expect(SlidingSegmentedControl.indicatorAlignment(1, 3), 0);
      expect(SlidingSegmentedControl.indicatorAlignment(2, 3), 1);
    });
  });

  group('SegmentedBody', () {
    List<SegmentPage> pages() => [
          SegmentPage.of(label: 'One', child: const Text('body one')),
          SegmentPage.of(label: 'Two', child: const Text('body two')),
        ];

    testWidgets('shows only the selected body', (tester) async {
      await tester.pumpWidget(host(SegmentedBody(pages: pages())));

      expect(find.text('body one'), findsOneWidget);
      expect(find.text('body two'), findsNothing);
    });

    testWidgets('switches body on tap when uncontrolled', (tester) async {
      await tester.pumpWidget(host(SegmentedBody(pages: pages())));

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(find.text('body two'), findsOneWidget);
      expect(find.text('body one'), findsNothing);
    });

    testWidgets('honours initialIndex', (tester) async {
      await tester.pumpWidget(
        host(SegmentedBody(pages: pages(), initialIndex: 1)),
      );

      expect(find.text('body two'), findsOneWidget);
    });

    testWidgets('a controlled body does not move on its own', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SegmentedBody(
        pages: pages(),
        selectedIndex: 0,
        onSegmentChanged: taps.add,
      )));

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(taps, [1]);
      expect(find.text('body one'), findsOneWidget);
    });

    testWidgets('clamps its own index when the page list shrinks',
        (tester) async {
      await tester.pumpWidget(
        host(SegmentedBody(pages: pages(), initialIndex: 1)),
      );
      await tester.pumpWidget(host(SegmentedBody(
        pages: [
          SegmentPage.of(label: 'One', child: const Text('body one')),
        ],
      )));
      await tester.pumpAndSettle();

      expect(find.text('body one'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SegmentedBody transitions', () {
    List<SegmentPage> pages() => [
          SegmentPage.of(label: 'One', child: const Text('body one')),
          SegmentPage.of(label: 'Two', child: const Text('body two')),
          SegmentPage.of(label: 'Three', child: const Text('body three')),
        ];

    /// Where the body sits, part-way through the switch.
    Future<double> bodyOffsetMidSwitch(
      WidgetTester tester,
      String tapLabel,
      String bodyText,
    ) async {
      await tester.tap(find.text(tapLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      return tester.getRect(find.text(bodyText)).center.dx;
    }

    testWidgets('fade is the default and does not move the body',
        (tester) async {
      await tester.pumpWidget(host(SegmentedBody(pages: pages())));
      final settled = tester.getRect(find.text('body one')).center.dx;

      final moving = await bodyOffsetMidSwitch(tester, 'Two', 'body two');
      expect(moving, closeTo(settled, 0.01));
      await tester.pumpAndSettle();
    });

    testWidgets('slide enters from the end side when moving forward',
        (tester) async {
      await tester.pumpWidget(host(SegmentedBody(
        pages: pages(),
        bodyTransition: SegmentedBodyTransition.slide,
      )));
      final settled = tester.getRect(find.text('body one')).center.dx;

      final moving = await bodyOffsetMidSwitch(tester, 'Two', 'body two');
      expect(moving, greaterThan(settled));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('body two')).center.dx,
        closeTo(settled, 0.01),
      );
    });

    testWidgets('slide enters from the start side when moving back',
        (tester) async {
      await tester.pumpWidget(host(SegmentedBody(
        pages: pages(),
        initialIndex: 2,
        bodyTransition: SegmentedBodyTransition.slide,
      )));
      final settled = tester.getRect(find.text('body three')).center.dx;

      final moving = await bodyOffsetMidSwitch(tester, 'One', 'body one');
      expect(moving, lessThan(settled));
      await tester.pumpAndSettle();
    });

    testWidgets('slide mirrors under RTL', (tester) async {
      await tester.pumpWidget(host(
        SegmentedBody(
          pages: pages(),
          bodyTransition: SegmentedBodyTransition.slide,
        ),
        direction: TextDirection.rtl,
      ));
      final settled = tester.getRect(find.text('body one')).center.dx;

      // Forward under RTL means the end side, which is the left.
      final moving = await bodyOffsetMidSwitch(tester, 'Two', 'body two');
      expect(moving, lessThan(settled));
      await tester.pumpAndSettle();
    });

    testWidgets('the outgoing body leaves the other way', (tester) async {
      await tester.pumpWidget(host(SegmentedBody(
        pages: pages(),
        bodyTransition: SegmentedBodyTransition.slide,
      )));
      final settled = tester.getRect(find.text('body one')).center.dx;

      await tester.tap(find.text('Two'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // Incoming from the right, so the outgoing one must be heading left.
      expect(tester.getRect(find.text('body one')).center.dx,
          lessThan(settled));
      expect(tester.getRect(find.text('body two')).center.dx,
          greaterThan(settled));
      await tester.pumpAndSettle();
    });

    testWidgets('a controlled body slides the way the host moved it',
        (tester) async {
      Widget at(int index) => host(SegmentedBody(
            pages: pages(),
            selectedIndex: index,
            bodyTransition: SegmentedBodyTransition.slide,
            onSegmentChanged: (_) {},
          ));

      await tester.pumpWidget(at(2));
      final settled = tester.getRect(find.text('body three')).center.dx;

      await tester.pumpWidget(at(0));
      await tester.pump(const Duration(milliseconds: 60));

      expect(tester.getRect(find.text('body one')).center.dx,
          lessThan(settled));
      await tester.pumpAndSettle();
    });

    testWidgets('scale settles the body at full size', (tester) async {
      await tester.pumpWidget(host(SegmentedBody(
        pages: pages(),
        bodyTransition: SegmentedBodyTransition.scale,
      )));

      await tester.tap(find.text('Two'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final growing = tester.getRect(find.text('body two')).width;

      await tester.pumpAndSettle();
      final settled = tester.getRect(find.text('body two')).width;
      expect(growing, lessThan(settled));
    });

    testWidgets('a custom transitionBuilder wins over bodyTransition',
        (tester) async {
      var used = 0;
      await tester.pumpWidget(host(SegmentedBody(
        pages: pages(),
        bodyTransition: SegmentedBodyTransition.slide,
        transitionBuilder: (child, animation) {
          used++;
          return FadeTransition(opacity: animation, child: child);
        },
      )));

      expect(used, greaterThan(0));
      expect(
        find.descendant(
          of: find.byType(SegmentedBody),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
    });
  });

  group('SegmentedControlTheme', () {
    testWidgets('falls back to the ColorScheme with no extension registered',
        (tester) async {
      late SegmentedControlTheme resolved;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          resolved = SegmentedControlTheme.of(context);
          return const SizedBox();
        }),
      ));

      expect(resolved.indicatorColor, isNotNull);
      expect(resolved.height, 44);
    });

    test('smooth corners give a superellipse, plain ones a rectangle', () {
      final base = SegmentedControlTheme.fromScheme(
        ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
      );

      expect(base.resolvedTrackShape, isA<RoundedSuperellipseBorder>());
      expect(base.resolvedIndicatorShape, isA<RoundedSuperellipseBorder>());

      final plain = base.copyWith(smoothCorners: false);
      expect(plain.resolvedTrackShape, isA<RoundedRectangleBorder>());
      expect(plain.resolvedIndicatorShape, isA<RoundedRectangleBorder>());
    });

    test('any BorderRadiusGeometry is carried through as given', () {
      const perCorner = BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomRight: Radius.elliptical(8, 4),
      );
      const directional = BorderRadiusDirectional.horizontal(
        start: Radius.circular(12),
      );

      final theme = SegmentedControlTheme.fromScheme(
        ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
      ).copyWith(trackRadius: perCorner, indicatorRadius: directional);

      expect(
        (theme.resolvedTrackShape as RoundedSuperellipseBorder).borderRadius,
        perCorner,
      );
      expect(
        (theme.resolvedIndicatorShape as RoundedSuperellipseBorder)
            .borderRadius,
        directional,
      );
    });

    testWidgets('per-instance radii win over the theme', (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        onSegmentChanged: (_) {},
        indicatorRadius: BorderRadius.circular(18),
      )));

      final decorated = tester.widget<DecoratedBox>(indicatorBox);
      final shape = (decorated.decoration as ShapeDecoration).shape;
      expect(
        (shape as RoundedSuperellipseBorder).borderRadius,
        BorderRadius.circular(18),
      );
    });

    testWidgets('a per-instance shape replaces the default entirely',
        (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        onSegmentChanged: (_) {},
        indicatorShape: const StadiumBorder(),
      )));

      final decorated = tester.widget<DecoratedBox>(indicatorBox);
      expect(
        (decorated.decoration as ShapeDecoration).shape,
        isA<StadiumBorder>(),
      );
    });

    test('copyWith replaces only what it is given', () {
      final base = SegmentedControlTheme.fromScheme(
        ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
      );
      final copy = base.copyWith(height: 56);

      expect(copy.height, 56);
      expect(copy.indicatorColor, base.indicatorColor);
      expect(copy.trackColor, base.trackColor);
    });

    test('lerp walks from one palette to the other', () {
      const a = SegmentedControlTheme(
        trackColor: Color(0xFF000000),
        borderColor: Color(0xFF000000),
        indicatorColor: Color(0xFF000000),
        selectedLabelColor: Color(0xFF000000),
        unselectedLabelColor: Color(0xFF000000),
        height: 40,
      );
      final b = a.copyWith(
        indicatorColor: const Color(0xFFFFFFFF),
        height: 60,
      );

      final mid = a.lerp(b, 0.5);
      expect(mid.height, 50);
      expect(mid.indicatorColor.a, 1.0);
      expect(mid.indicatorColor, isNot(a.indicatorColor));
    });

    test('disabled labels dim the unselected colour by default', () {
      const theme = SegmentedControlTheme(
        trackColor: Color(0xFF000000),
        borderColor: Color(0xFF000000),
        indicatorColor: Color(0xFF000000),
        selectedLabelColor: Color(0xFFFFFFFF),
        unselectedLabelColor: Color(0xFF888888),
      );

      final disabled = theme.colorFor(selected: false, enabled: false);
      expect(disabled.a, closeTo(0.38, 0.01));
    });
  });

  Rect segmentRect(WidgetTester tester, int index) =>
      tester.getRect(find.byKey(SlidingSegmentedControl.segmentKey(index)));

  group('keyboard', () {
    testWidgets('an arrow key moves the selection along', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        autofocus: true,
        onSegmentChanged: taps.add,
      )));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(taps, [1]);
    });

    testWidgets('the arrow keys mirror under RTL', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(
        SlidingSegmentedControl(
          segments: segments,
          selectedIndex: 1,
          autofocus: true,
          onSegmentChanged: taps.add,
        ),
        direction: TextDirection.rtl,
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(taps, [0], reason: 'right moves towards the start under RTL');
    });

    testWidgets('an arrow key steps over a disabled segment', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: const [
          Segment(label: 'One'),
          Segment(label: 'Two', enabled: false),
          Segment(label: 'Three'),
        ],
        selectedIndex: 0,
        autofocus: true,
        onSegmentChanged: taps.add,
      )));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(taps, [2]);
    });

    testWidgets('an arrow key stops at the end rather than wrapping',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 2,
        autofocus: true,
        onSegmentChanged: taps.add,
      )));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(taps, isEmpty);
    });

    testWidgets('home and end jump to the first and last segment',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 1,
        autofocus: true,
        onSegmentChanged: taps.add,
      )));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      expect(taps, [2, 0]);
    });

    testWidgets('enter activates the focused segment', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        autofocus: true,
        onSegmentChanged: taps.add,
      )));
      await tester.pump();

      // The host holds selectedIndex at 0, so focus lands on segment 1 while
      // the selection stays put — and Enter reports it again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, [1, 1]);
    });

    testWidgets('the focused segment draws a focus ring', (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        autofocus: true,
        onSegmentChanged: (_) {},
      )));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      final rings = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).where(
            (box) =>
                box.decoration is ShapeDecoration &&
                ((box.decoration as ShapeDecoration).shape as OutlinedBorder)
                        .side
                        .width >
                    0,
          );
      expect(rings, isNotEmpty);
    });

    testWidgets('only the selected segment is a tab stop', (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 1,
        onSegmentChanged: (_) {},
      )));

      final nodes = tester
          .widgetList<Focus>(find.byType(Focus))
          .map((focus) => focus.focusNode)
          .whereType<FocusNode>()
          .where((node) => node.debugLabel?.startsWith('Segment') ?? false)
          .toList();
      expect(nodes.length, 3);
      expect(
        [for (final node in nodes) node.skipTraversal],
        [true, false, true],
      );
    });

    testWidgets('a disabled control takes no keys', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        enabled: false,
        autofocus: true,
        onSegmentChanged: taps.add,
      )));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(taps, isEmpty);
    });
  });

  group('pointer', () {
    testWidgets('a hovered segment takes the hover overlay', (tester) async {
      // Hover highlights are only drawn where a pointer is expected, which
      // the focus manager reads off the platform. Reset inside the body: the
      // framework checks for stray debug flags before tear-downs run.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      const hover = Color(0xFF123456);
      await tester.pumpWidget(host(
        SlidingSegmentedControl(
          segments: segments,
          selectedIndex: 0,
          onSegmentChanged: (_) {},
        ),
        theme: SegmentedControlTheme.fromScheme(const ColorScheme.light())
            .copyWith(hoverColor: hover),
      ));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.text('Two')));
      await tester.pumpAndSettle();

      final overlays = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((box) =>
              box.decoration is ShapeDecoration &&
              (box.decoration as ShapeDecoration).color == hover);
      expect(overlays, hasLength(1));
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('dragging', () {
    testWidgets('dragging the pill picks the segment it lands on',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        onSegmentChanged: taps.add,
      )));

      await tester.drag(
        find.byKey(SlidingSegmentedControl.segmentKey(0)),
        const Offset(200, 0),
      );
      await tester.pumpAndSettle();
      expect(taps, [2]);
    });

    testWidgets('a short drag settles back where it started', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        onSegmentChanged: taps.add,
      )));

      await tester.drag(
        find.byKey(SlidingSegmentedControl.segmentKey(0)),
        const Offset(30, 0),
      );
      await tester.pumpAndSettle();
      expect(taps, isEmpty);
    });

    testWidgets('the indicator follows the pointer mid-drag', (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        onSegmentChanged: (_) {},
      )));
      final start = tester.getRect(indicator).left;

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(SlidingSegmentedControl.segmentKey(0))),
      );
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();

      expect(tester.getRect(indicator).left, greaterThan(start));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a drag that does not start on the pill is ignored',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        onSegmentChanged: taps.add,
      )));

      await tester.drag(
        find.byKey(SlidingSegmentedControl.segmentKey(2)),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(taps, isEmpty);
    });

    testWidgets('enableDrag: false leaves dragging alone', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: segments,
        selectedIndex: 0,
        enableDrag: false,
        onSegmentChanged: taps.add,
      )));

      await tester.drag(
        find.byKey(SlidingSegmentedControl.segmentKey(0)),
        const Offset(200, 0),
      );
      await tester.pumpAndSettle();
      expect(taps, isEmpty);
    });

    testWidgets('dragging runs the other way under RTL', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(
        SlidingSegmentedControl(
          segments: segments,
          selectedIndex: 0,
          onSegmentChanged: taps.add,
        ),
        direction: TextDirection.rtl,
      ));

      await tester.drag(
        find.byKey(SlidingSegmentedControl.segmentKey(0)),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(taps, [2]);
    });
  });

  group('sizing', () {
    const long = [
      Segment(label: 'A'),
      Segment(label: 'Considerably longer'),
      Segment(label: 'Mid'),
    ];

    testWidgets('equal segments share the width', (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: long,
        selectedIndex: 0,
        onSegmentChanged: (_) {},
      )));

      expect(
        segmentRect(tester, 0).width,
        closeTo(segmentRect(tester, 1).width, 0.01),
      );
    });

    testWidgets('intrinsic segments are as wide as their content',
        (tester) async {
      await tester.pumpWidget(host(
        SlidingSegmentedControl(
          segments: long,
          selectedIndex: 0,
          sizing: SegmentSizing.intrinsic,
          onSegmentChanged: (_) {},
        ),
        width: null,
      ));

      expect(
        segmentRect(tester, 1).width,
        greaterThan(segmentRect(tester, 0).width),
      );
    });

    testWidgets('an intrinsic control shrink-wraps its segments',
        (tester) async {
      await tester.pumpWidget(host(
        SlidingSegmentedControl(
          segments: long,
          selectedIndex: 0,
          sizing: SegmentSizing.intrinsic,
          onSegmentChanged: (_) {},
        ),
        width: null,
      ));

      final control = tester.getSize(find.byType(SlidingSegmentedControl));
      final segmentsWidth = [
        for (var i = 0; i < long.length; i++) segmentRect(tester, i).width,
      ].reduce((a, b) => a + b);
      // The track's 4px padding and 1px border on each side is all the slack
      // there is.
      expect(control.width, closeTo(segmentsWidth + 10, 0.01));
    });

    testWidgets('the indicator takes the selected segment\'s width',
        (tester) async {
      await tester.pumpWidget(host(
        SlidingSegmentedControl(
          segments: long,
          selectedIndex: 1,
          sizing: SegmentSizing.intrinsic,
          onSegmentChanged: (_) {},
        ),
        width: null,
      ));

      expect(tester.getRect(indicator), segmentRect(tester, 1));
    });

    testWidgets('intrinsic segments are squeezed rather than overflowing',
        (tester) async {
      await tester.pumpWidget(host(
        SlidingSegmentedControl(
          segments: long,
          selectedIndex: 0,
          sizing: SegmentSizing.intrinsic,
          onSegmentChanged: (_) {},
        ),
        width: 120,
      ));

      expect(tester.takeException(), isNull);
      final total = [
        for (var i = 0; i < long.length; i++) segmentRect(tester, i).width,
      ].reduce((a, b) => a + b);
      expect(total, closeTo(110, 0.01));
    });

    testWidgets('a scrollable control lets its segments overflow',
        (tester) async {
      final many = [
        for (var i = 0; i < 10; i++) Segment(label: 'Segment $i'),
      ];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: many,
        selectedIndex: 0,
        sizing: SegmentSizing.scrollable,
        onSegmentChanged: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position
            .maxScrollExtent,
        greaterThan(0),
        reason: 'the segments are wider than the track, and scroll',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a scrollable control brings the selection into view',
        (tester) async {
      final many = [
        for (var i = 0; i < 10; i++) Segment(label: 'Segment $i'),
      ];
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: many,
        selectedIndex: 9,
        sizing: SegmentSizing.scrollable,
        onSegmentChanged: (_) {},
      )));
      await tester.pumpAndSettle();

      final control = tester.getRect(find.byType(SlidingSegmentedControl));
      final selected = segmentRect(tester, 9);
      expect(selected.left, greaterThanOrEqualTo(control.left - 0.01));
      expect(selected.right, lessThanOrEqualTo(control.right + 0.01));
    });
  });

  group('Segment', () {
    testWidgets('a child replaces the label but not the semantics',
        (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: const [
          Segment(label: 'One', child: Text('Custom')),
          Segment(label: 'Two'),
        ],
        selectedIndex: 0,
        onSegmentChanged: (_) {},
      )));

      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('One'), findsNothing);
      final semantics = tester
          .getSemantics(find.byKey(SlidingSegmentedControl.segmentKey(0)));
      expect(semantics.label, 'One');
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    });

    testWidgets('a badge is shown after the label', (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: const [
          Segment(label: 'Inbox', badge: Text('3')),
          Segment(label: 'Sent'),
        ],
        selectedIndex: 0,
        onSegmentChanged: (_) {},
      )));

      expect(find.text('3'), findsOneWidget);
      expect(
        tester.getCenter(find.text('3')).dx,
        greaterThan(tester.getCenter(find.text('Inbox')).dx),
      );
    });

    testWidgets('an iconWidget takes the segment\'s colour', (tester) async {
      await tester.pumpWidget(host(SlidingSegmentedControl(
        segments: const [
          Segment(label: 'One', iconWidget: Icon(Icons.star)),
          Segment(label: 'Two'),
        ],
        selectedIndex: 0,
        onSegmentChanged: (_) {},
        selectedLabelColor: const Color(0xFF00FF00),
      )));

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.star))).color,
        const Color(0xFF00FF00),
      );
      expect(icon.icon, Icons.star);
    });

    test('copyWith replaces only what it is given', () {
      const segment = Segment(label: 'One', tooltip: 'First');
      final copy = segment.copyWith(label: 'Two');
      expect(copy.label, 'Two');
      expect(copy.tooltip, 'First');
    });

    test('segments and pages compare by value', () {
      expect(const Segment(label: 'One'), const Segment(label: 'One'));
      expect(
        const Segment(label: 'One'),
        isNot(const Segment(label: 'One', enabled: false)),
      );
      const body = Text('a');
      expect(
        const SegmentPage(segment: Segment(label: 'One'), child: body),
        const SegmentPage(segment: Segment(label: 'One'), child: body),
      );
      expect(
        const SegmentPage(segment: Segment(label: 'One'), child: body),
        isNot(const SegmentPage(segment: Segment(label: 'Two'), child: body)),
      );
    });
  });
}
