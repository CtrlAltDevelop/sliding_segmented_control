import 'package:material_ui/material_ui.dart';
import 'package:sliding_segmented_control/sliding_segmented_control.dart';

import 'demo_theme.dart';
import 'demo_panel.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sliding_segmented_control',
      debugShowCheckedModeBanner: false,
      theme: buildDemoTheme(Brightness.light),
      darkTheme: buildDemoTheme(Brightness.dark),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  int _controlled = 0;
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('sliding_segmented_control'),
          actions: [
            IconButton(
              tooltip: 'Toggle text direction',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => setState(() => _rtl = !_rtl),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionTitle('Controlled'),
            SlidingSegmentedControl(
              segments: const [
                Segment(label: 'Buy'),
                Segment(label: 'Sell'),
                Segment(label: 'History'),
              ],
              selectedIndex: _controlled,
              onSegmentChanged: (i) => setState(() => _controlled = i),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected index: $_controlled — tap a segment, drag the pill, '
              'or tab to the control and use the arrow keys.',
              style: theme.textTheme.bodySmall,
            ),

            const _SectionTitle('With icons'),
            _Uncontrolled(
              builder: (index, onChanged) => SlidingSegmentedControl(
                segments: const [
                  Segment(label: 'List', icon: Icons.view_list),
                  Segment(label: 'Grid', icon: Icons.grid_view),
                  Segment(label: 'Map', icon: Icons.map_outlined),
                ],
                selectedIndex: index,
                onSegmentChanged: onChanged,
              ),
            ),

            const _SectionTitle('Solid indicator, per-instance override'),
            _Uncontrolled(
              builder: (index, onChanged) => SlidingSegmentedControl(
                segments: const [
                  Segment(label: 'Day'),
                  Segment(label: 'Week'),
                  Segment(label: 'Month'),
                  Segment(label: 'Year'),
                ],
                selectedIndex: index,
                onSegmentChanged: onChanged,
                indicatorColor: theme.colorScheme.primary,
                selectedLabelColor: theme.colorScheme.onPrimary,
              ),
            ),

            const _SectionTitle('A disabled segment'),
            _Uncontrolled(
              builder: (index, onChanged) => SlidingSegmentedControl(
                segments: const [
                  Segment(label: 'Draft'),
                  Segment(label: 'Review'),
                  Segment(label: 'Published', enabled: false),
                ],
                selectedIndex: index,
                onSegmentChanged: onChanged,
              ),
            ),

            const _SectionTitle('Content-sized segments'),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _Uncontrolled(
                builder: (index, onChanged) => SlidingSegmentedControl(
                  sizing: SegmentSizing.intrinsic,
                  segments: const [
                    Segment(label: 'All'),
                    Segment(label: 'Needs attention'),
                    Segment(label: 'Done'),
                  ],
                  selectedIndex: index,
                  onSegmentChanged: onChanged,
                ),
              ),
            ),

            const _SectionTitle('Scrollable, for more segments than fit'),
            _Uncontrolled(
              builder: (index, onChanged) => SlidingSegmentedControl(
                sizing: SegmentSizing.scrollable,
                segments: const [
                  Segment(label: 'Monday'),
                  Segment(label: 'Tuesday'),
                  Segment(label: 'Wednesday'),
                  Segment(label: 'Thursday'),
                  Segment(label: 'Friday'),
                  Segment(label: 'Saturday'),
                  Segment(label: 'Sunday'),
                ],
                selectedIndex: index,
                onSegmentChanged: onChanged,
              ),
            ),

            const _SectionTitle('Badges and content of your own'),
            _Uncontrolled(
              builder: (index, onChanged) => SlidingSegmentedControl(
                segments: [
                  Segment(
                    label: 'Inbox',
                    icon: Icons.inbox_outlined,
                    badge: _Count(12, theme: theme),
                  ),
                  const Segment(label: 'Sent', icon: Icons.send_outlined),
                  Segment(
                    label: 'Archive',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: theme.colorScheme.tertiary,
                        ),
                        const Text('Archive'),
                      ],
                    ),
                  ),
                ],
                selectedIndex: index,
                onSegmentChanged: onChanged,
              ),
            ),

            const _SectionTitle('SegmentedBody, with a direction-aware slide'),
            SegmentedBody(
              bodyTransition: SegmentedBodyTransition.slide,
              pages: [
                SegmentPage.of(
                  label: 'Overview',
                  icon: Icons.dashboard_outlined,
                  child: const DemoPanel(
                    title: 'Overview',
                    body: 'Only the selected page is built.',
                  ),
                ),
                SegmentPage.of(
                  label: 'Activity',
                  icon: Icons.timeline,
                  child: const DemoPanel(
                    title: 'Activity',
                    body: 'The body slides the way the selection moved.',
                  ),
                ),
                SegmentPage.of(
                  label: 'Settings',
                  icon: Icons.tune,
                  child: const DemoPanel(
                    title: 'Settings',
                    body: 'Pass a transitionBuilder for anything else.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Holds the selection for the demos that do not need it lifted any higher.
class _Uncontrolled extends StatefulWidget {
  const _Uncontrolled({required this.builder});

  final Widget Function(int index, ValueChanged<int> onChanged) builder;

  @override
  State<_Uncontrolled> createState() => _UncontrolledState();
}

class _UncontrolledState extends State<_Uncontrolled> {
  int _index = 0;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_index, (i) => setState(() => _index = i));
}

/// A pill of a badge, for the segment that carries a count.
class _Count extends StatelessWidget {
  const _Count(this.value, {required this.theme});

  final int value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: ShapeDecoration(
          color: theme.colorScheme.tertiaryContainer,
          shape: const StadiumBorder(),
        ),
        child: Text(
          '$value',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 10),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}
