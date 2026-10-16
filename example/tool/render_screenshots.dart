import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_matchers/layout_matchers.dart';
import 'package:layout_matchers_example/main.dart';

import 'readme_shots.dart';

Finder _key(Key key) => find.byKey(key, skipOffstage: false);

final Finder _title = _key(SignUpKeys.title);
final Finder _subtitle = _key(SignUpKeys.subtitle);
final Finder _submit = _key(SignUpKeys.submit);
final List<Finder> _fields = <Finder>[
  _key(SignUpKeys.name),
  _key(SignUpKeys.email),
  _key(SignUpKeys.password),
  _key(SignUpKeys.confirm),
];

/// One `expect` shown in the demo, with its result.
class _Check {
  _Check(this.code, this.item, this.matcher);

  final String code;
  final Object item;
  final Matcher matcher;
  String? failure;
  bool passed = true;

  void run() {
    final Map<dynamic, dynamic> state = <dynamic, dynamic>{};
    passed = matcher.matches(item, state);
    failure = passed
        ? null
        : matcher
              .describeMismatch(item, StringDescription(), state, false)
              .toString();
  }
}

List<_Check> _checks() => <_Check>[
  _Check(
    'expect([title, subtitle, ...fields, submit],\n    findsInOrder());',
    <Finder>[_title, _subtitle, ..._fields, _submit],
    findsInOrder(),
  ),
  _Check(
    'expect(fields, findsEvenlySpaced(gap: 16));',
    _fields,
    findsEvenlySpaced(gap: 16),
  ),
  _Check(
    'expect([title, name, submit],\n    findsAligned(LayoutEdge.left));',
    <Finder>[_title, _fields.first, _submit],
    findsAligned(LayoutEdge.left),
  ),
  _Check('expect(submit, isFullyVisible);', _submit, isFullyVisible),
];

typedef _DemoState = (double, List<_Check>?, List<(Rect, bool)>);

final ValueNotifier<_DemoState> _demo = ValueNotifier<_DemoState>((
  1,
  null,
  const <(Rect, bool)>[],
));

final GlobalKey _stackKey = GlobalKey();

class _DemoScene extends StatelessWidget {
  const _DemoScene();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_DemoState>(
      valueListenable: _demo,
      builder: (BuildContext context, _DemoState state, _) {
        final (double textScale, List<_Check>? checks, outlines) = state;
        return _buildScene(textScale, checks, outlines);
      },
    );
  }

  Widget _buildScene(
    double textScale,
    List<_Check>? checks,
    List<(Rect, bool)> outlines,
  ) {
    return Stack(
      key: _stackKey,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            caption(
              'Layout checks in a widget test',
              detail: 'Text scale ${textScale.toStringAsFixed(1)}×',
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                phone(
                  Builder(
                    builder: (BuildContext context) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(textScale)),
                      child: const SignUpScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 340,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final _Check check in checks ?? <_Check>[])
                        _CheckTile(check),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _OutlinePainter(outlines)),
          ),
        ),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile(this.check);

  final _Check check;

  @override
  Widget build(BuildContext context) {
    final Color color = check.passed
        ? const Color(0xFF188038)
        : const Color(0xFFD93025);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: check.passed ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(check.passed ? Icons.check_circle : Icons.cancel, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  check.code,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
                if (check.failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      check.failure!,
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinePainter extends CustomPainter {
  _OutlinePainter(this.outlines);

  final List<(Rect, bool)> outlines;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (Rect rect, bool ok) in outlines) {
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ok ? const Color(0xAA1A73E8) : const Color(0xFFD93025),
      );
    }
  }

  @override
  bool shouldRepaint(_OutlinePainter oldDelegate) => true;
}

/// Shows the demo at [textScale], runs the checks, and pumps again with the
/// results and outlines drawn.
Future<void> _showScale(WidgetTester tester, double textScale) async {
  _demo.value = (textScale, null, const <(Rect, bool)>[]);
  await tester.pump();
  final List<_Check> checks = _checks()..forEach((_Check c) => c.run());
  final RenderBox stack =
      _stackKey.currentContext!.findRenderObject()! as RenderBox;
  final Offset origin = stack.localToGlobal(Offset.zero);
  final bool submitOk = checks.last.passed;
  final List<(Rect, bool)> outlines = <(Rect, bool)>[
    for (final Finder f in <Finder>[_title, _subtitle, ..._fields, _submit])
      if (visibleRectOf(f) != Rect.zero)
        (visibleRectOf(f).shift(-origin), f != _submit || submitOk),
  ];
  _demo.value = (textScale, checks, outlines);
  await tester.pump();
}

Future<GlobalKey> _pumpDemo(WidgetTester tester) =>
    pumpShot(tester, const Size(780, 760), const _DemoScene());

void main() {
  setUpAll(loadShotFonts);

  testWidgets('demo.gif', (WidgetTester tester) async {
    const List<double> scales = <double>[1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6];
    final GifRecorder gif = GifRecorder(
      tester,
      await _pumpDemo(tester),
      width: 520,
    );
    for (int i = 0; i < scales.length; i++) {
      await _showScale(tester, scales[i]);
      await gif.frame(i == 0 || i == scales.length - 1 ? 180 : 45);
    }
    gif.save('demo.gif');
  });

  testWidgets('large_text.png', (WidgetTester tester) async {
    final GlobalKey boundary = await _pumpDemo(tester);
    await _showScale(tester, 1.6);
    expect(_submit, isNot(isFullyVisible));
    writeDoc('large_text.png', await snapshot(tester, boundary));
  });

  testWidgets('comparison.png', (WidgetTester tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(360, 640) * 2;
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(const SignUpApp());

    String failureOf(void Function() body) {
      try {
        body();
      } on TestFailure catch (failure) {
        return failure.message ?? '';
      }
      return 'passed';
    }

    final String usual = failureOf(() {
      final Rect rect = tester.getRect(_submit);
      expect(rect.bottom <= 640, isTrue);
    });
    final String ours = failureOf(() => expect(_submit, isFullyVisible));
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    // Keep the matcher lines; drop the long finder dump in "Actual:".
    String trim(String message) => message
        .split('\n')
        .map((String l) => l.trim())
        .where(
          (String l) =>
              l.startsWith('Expected') ||
              l.startsWith('Which') ||
              (l.startsWith('Actual') && l.length < 40),
        )
        .join('\n');

    Widget panel(String title, String code, String output) => Container(
      width: 360,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          caption(title),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF1F3F4),
            child: Text(
              code,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Test output at 1.6× text:',
            style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFCE8E6),
            child: Text(
              trim(output),
              style: const TextStyle(fontSize: 13, color: Color(0xFFB3261E)),
            ),
          ),
        ],
      ),
    );

    await writePng(
      tester,
      'comparison.png',
      const Size(800, 260),
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          panel(
            'The usual way',
            'final rect = tester.getRect(submit);\n'
                'expect(rect.bottom <= 640, isTrue);',
            usual,
          ),
          panel('layout_matchers', 'expect(submit, isFullyVisible);', ours),
        ],
      ),
    );
  });
}
