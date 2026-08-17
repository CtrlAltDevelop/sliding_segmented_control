// Records the README's animated GIF from the real widgets:
//
//   cd example && flutter test tool/record_tab_gif.dart
//
// It drives a SegmentedBody through its segments, grabs a frame every 50ms,
// and encodes them into ../../screenshots/tabs.gif.
//
// It lives outside test/ on purpose: it writes a file rather than asserting
// anything, so it should not run as part of `flutter test`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sliding_segmented_control/sliding_segmented_control.dart';
import 'package:sliding_segmented_control_example/demo_panel.dart';
import 'package:sliding_segmented_control_example/demo_theme.dart';

/// The recorded canvas, in logical pixels. Kept tight so the GIF stays light.
const Size _canvasSize = Size(600, 210);

/// One frame every 50ms, which is 20fps — smooth enough for a 250ms slide.
const Duration _step = Duration(milliseconds: 50);

const Key _canvasKey = Key('canvas');

/// Loads the fonts the widgets actually draw with; `flutter test` otherwise
/// renders every glyph as an Ahem box.
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

Widget _canvas() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildDemoTheme(Brightness.light),
      home: RepaintBoundary(
        key: _canvasKey,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SegmentedBody(
              bodyTransition: SegmentedBodyTransition.slide,
              pages: [
                SegmentPage.of(
                  label: 'Overview',
                  icon: Icons.dashboard_outlined,
                  child: const DemoPanel(
                    title: 'Overview',
                    body: 'The pill slides between segments.',
                  ),
                ),
                SegmentPage.of(
                  label: 'Activity',
                  icon: Icons.timeline,
                  child: const DemoPanel(
                    title: 'Activity',
                    body: 'The body follows the way the selection moved.',
                  ),
                ),
                SegmentPage.of(
                  label: 'Settings',
                  icon: Icons.tune,
                  child: const DemoPanel(
                    title: 'Settings',
                    body: 'Going back sends it the other way.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(_loadFonts);

  testWidgets('record the tab-change GIF', (tester) async {
    tester.view
      ..physicalSize = _canvasSize
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_canvas());
    await tester.pumpAndSettle();

    final frames = <img.Image>[];

    /// Grabs whatever is on screen right now.
    Future<void> grab() async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(_canvasKey));
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        frames.add(
          img.Image.fromBytes(
            width: image.width,
            height: image.height,
            bytes: Uint8List.fromList(data!.buffer.asUint8List()).buffer,
            numChannels: 4,
          ),
        );
      });
    }

    /// Advances the clock, grabbing a frame per step.
    Future<void> roll(Duration total) async {
      for (var t = Duration.zero; t < total; t += _step) {
        await tester.pump(_step);
        await grab();
      }
    }

    /// Taps a segment, then records the change and the pause after it.
    Future<void> pick(String label) async {
      await tester.tap(find.text(label));
      await roll(const Duration(milliseconds: 500));
      await roll(const Duration(milliseconds: 350));
    }

    await grab();
    await roll(const Duration(milliseconds: 300));
    await pick('Activity');
    await pick('Settings');
    await pick('Overview');

    // The UI is flat colour, so dithering only adds noise and weight.
    final encoder = img.GifEncoder(repeat: 0, dither: img.DitherKernel.none)
      ..delay = _step.inMilliseconds ~/ 10;
    for (final frame in frames) {
      encoder.addFrame(frame, duration: _step.inMilliseconds ~/ 10);
    }

    final bytes = encoder.finish();
    expect(bytes, isNotNull, reason: 'the encoder produced no GIF');

    final out = File('../screenshots/tabs.gif')..writeAsBytesSync(bytes!);
    // ignore: avoid_print — this is a generator script, not a test.
    print('wrote ${out.path}: ${frames.length} frames, '
        '${(bytes.length / 1024).round()} KB');
  });
}
