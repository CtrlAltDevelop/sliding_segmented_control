// Renders the README screenshots from the real widgets, so they can be
// regenerated whenever the control changes:
//
//   cd example && flutter test --update-goldens test/screenshots_test.dart
//
// The images land in ../../screenshots/ and are shown in README.md.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_segmented_control/sliding_segmented_control.dart';
import 'package:sliding_segmented_control_example/demo_panel.dart';
import 'package:sliding_segmented_control_example/demo_theme.dart';

/// `flutter test` renders text with the placeholder Ahem font unless real
/// fonts are registered, so load the ones the control actually draws with.
Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    await (FontLoader(family)
          ..addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer))))
        .load();
  }

  await load('Roboto', '$fonts/Roboto-Regular.ttf');
  await load('MaterialIcons', '$fonts/MaterialIcons-Regular.otf');
}

/// The widgets on a plain backdrop, at the width they are shown at.
Widget _canvas(List<Widget> children) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildDemoTheme(Brightness.light),
      home: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 20,
              children: children,
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(_loadFonts);

  testWidgets('the control, in three styles', (tester) async {
    tester.view
      ..physicalSize = const Size(880, 460)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_canvas([
      SlidingSegmentedControl(
        segments: const [
          Segment(label: 'Buy'),
          Segment(label: 'Sell'),
          Segment(label: 'History'),
        ],
        selectedIndex: 0,
        onSegmentChanged: (_) {},
      ),
      SlidingSegmentedControl(
        segments: const [
          Segment(label: 'List', icon: Icons.view_list),
          Segment(label: 'Grid', icon: Icons.grid_view),
          Segment(label: 'Map', icon: Icons.map_outlined),
        ],
        selectedIndex: 1,
        onSegmentChanged: (_) {},
      ),
      SlidingSegmentedControl(
        segments: const [
          Segment(label: 'Day'),
          Segment(label: 'Week'),
          Segment(label: 'Month'),
          Segment(label: 'Year'),
        ],
        selectedIndex: 2,
        onSegmentChanged: (_) {},
        indicatorColor: const Color(0xFF3B82F6),
        selectedLabelColor: const Color(0xFFFFFFFF),
      ),
    ]));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../screenshots/control.png'),
    );
  });

  testWidgets('the sizing modes', (tester) async {
    tester.view
      ..physicalSize = const Size(880, 460)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_canvas([
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: SlidingSegmentedControl(
          sizing: SegmentSizing.intrinsic,
          segments: const [
            Segment(label: 'All'),
            Segment(label: 'Needs attention'),
            Segment(label: 'Done'),
          ],
          selectedIndex: 1,
          onSegmentChanged: (_) {},
        ),
      ),
      SlidingSegmentedControl(
        sizing: SegmentSizing.scrollable,
        segments: const [
          Segment(label: 'Monday'),
          Segment(label: 'Tuesday'),
          Segment(label: 'Wednesday'),
          Segment(label: 'Thursday'),
          Segment(label: 'Friday'),
          Segment(label: 'Saturday'),
        ],
        selectedIndex: 0,
        onSegmentChanged: (_) {},
      ),
      SlidingSegmentedControl(
        segments: [
          Segment(
            label: 'Inbox',
            icon: Icons.inbox_outlined,
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: const ShapeDecoration(
                color: Color(0xFFDCE7FF),
                shape: StadiumBorder(),
              ),
              child: const Text(
                '12',
                style: TextStyle(fontSize: 11, color: Color(0xFF1B3A78)),
              ),
            ),
          ),
          const Segment(label: 'Sent', icon: Icons.send_outlined),
          const Segment(label: 'Archive', icon: Icons.archive_outlined),
        ],
        selectedIndex: 0,
        onSegmentChanged: (_) {},
      ),
    ]));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../screenshots/sizing.png'),
    );
  });

  testWidgets('a SegmentedBody', (tester) async {
    tester.view
      ..physicalSize = const Size(880, 460)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_canvas([
      SegmentedBody(
        initialIndex: 1,
        pages: [
          SegmentPage.of(
            label: 'Overview',
            icon: Icons.dashboard_outlined,
            child: const DemoPanel(title: 'Overview', body: 'Not built yet.'),
          ),
          SegmentPage.of(
            label: 'Activity',
            icon: Icons.timeline,
            child: const DemoPanel(
              title: 'Activity',
              body: 'The body cross-fades as the pill slides.',
            ),
          ),
          SegmentPage.of(
            label: 'Settings',
            icon: Icons.tune,
            child: const DemoPanel(title: 'Settings', body: 'Not built yet.'),
          ),
        ],
      ),
    ]));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../screenshots/body.png'),
    );
  });
}
