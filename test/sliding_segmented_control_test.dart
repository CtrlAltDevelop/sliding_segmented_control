import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_segmented_control/sliding_segmented_control.dart';

void main() {
  Widget host(
    Widget child, {
    TextDirection direction = TextDirection.ltr,
    SegmentedControlTheme? theme,
  }) =>
      MaterialApp(
        theme: ThemeData(extensions: theme == null ? const [] : [theme]),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Center(child: SizedBox(width: 300, child: child)),
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
}
