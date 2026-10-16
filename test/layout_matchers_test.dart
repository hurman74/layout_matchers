import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_matchers/layout_matchers.dart';

/// Pumps boxes at fixed global rectangles, keyed by name.
Future<void> pumpBoxes(WidgetTester tester, Map<String, Rect> boxes) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: <Widget>[
          for (final MapEntry<String, Rect> entry in boxes.entries)
            Positioned.fromRect(
              rect: entry.value,
              child: SizedBox(key: Key(entry.key)),
            ),
        ],
      ),
    ),
  );
}

Finder box(String name) => find.byKey(Key(name));

/// Returns `null` if [item] matches [matcher], or the mismatch text.
String? mismatch(Object? item, Matcher matcher) {
  final Map<dynamic, dynamic> state = <dynamic, dynamic>{};
  if (matcher.matches(item, state)) {
    return null;
  }
  return matcher
      .describeMismatch(item, StringDescription(), state, false)
      .toString();
}

String describe(Matcher matcher) =>
    matcher.describe(StringDescription()).toString();

void main() {
  group('globalRectOf / visibleRectOf', () {
    testWidgets('returns the global rectangle', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(10, 20, 30, 40),
      });
      expect(globalRectOf(box('a')), const Rect.fromLTWH(10, 20, 30, 40));
      expect(visibleRectOf(box('a')), const Rect.fromLTWH(10, 20, 30, 40));
    });

    testWidgets('applies transforms', (WidgetTester tester) async {
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: Transform.scale(
            scale: 2,
            alignment: Alignment.topLeft,
            child: const SizedBox(key: Key('a'), width: 10, height: 5),
          ),
        ),
      );
      expect(globalRectOf(box('a')), const Rect.fromLTWH(0, 0, 20, 10));
    });

    testWidgets('clips to the screen', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(780, 0, 40, 10),
        'gone': const Rect.fromLTWH(900, 0, 40, 10),
      });
      expect(visibleRectOf(box('a')), const Rect.fromLTWH(780, 0, 20, 10));
      expect(visibleRectOf(box('gone')), Rect.zero);
    });

    testWidgets('clips to ClipRect ancestors', (WidgetTester tester) async {
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: ClipRect(
            child: SizedBox(
              width: 50,
              height: 50,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: 100,
                maxHeight: 100,
                child: const SizedBox(key: Key('a'), width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      expect(globalRectOf(box('a')), const Rect.fromLTWH(0, 0, 100, 100));
      expect(visibleRectOf(box('a')), const Rect.fromLTWH(0, 0, 50, 50));
    });

    testWidgets('throws readable errors', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 10, 10),
        'b': const Rect.fromLTWH(0, 20, 10, 10),
      });
      expect(
        () => globalRectOf(box('missing')),
        throwsA(
          isA<LayoutResolutionException>().having(
            (LayoutResolutionException e) => e.message,
            'message',
            contains('found no widget'),
          ),
        ),
      );
      expect(
        () => globalRectOf(find.byType(SizedBox)),
        throwsA(
          isA<LayoutResolutionException>().having(
            (LayoutResolutionException e) => e.message,
            'message',
            contains('found 2 widgets'),
          ),
        ),
      );
    });

    testWidgets('rejects slivers', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(key: Key('s'), child: SizedBox(height: 50)),
            ],
          ),
        ),
      );
      expect(mismatch(box('s'), isVisible), contains('is not a box'));
    });
  });

  group('isAbove / isBelow / isLeftOf / isRightOf', () {
    testWidgets('match by edges', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'top': const Rect.fromLTWH(0, 0, 100, 20),
        'bottom': const Rect.fromLTWH(200, 30, 100, 20),
        'left': const Rect.fromLTWH(0, 100, 50, 50),
        'right': const Rect.fromLTWH(50, 300, 50, 50),
      });
      expect(box('top'), isAbove(box('bottom')));
      expect(box('bottom'), isBelow(box('top')));
      expect(box('left'), isLeftOf(box('right')));
      expect(box('right'), isRightOf(box('left')));
      expect(box('bottom'), isNot(isAbove(box('top'))));
      expect(box('left'), isNot(isRightOf(box('right'))));
    });

    testWidgets('touching edges count, overlap does not', (
      WidgetTester tester,
    ) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 10, 10),
        'b': const Rect.fromLTWH(0, 10, 10, 10),
        'c': const Rect.fromLTWH(0, 5, 10, 10),
      });
      expect(box('a'), isAbove(box('b')));
      expect(
        mismatch(box('a'), isAbove(box('c'))),
        allOf(
          contains('is not above'),
          contains('bottom edge is 5 px past the other\'s top edge'),
        ),
      );
    });

    testWidgets('gap, minGap and maxGap', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 10, 10),
        'b': const Rect.fromLTWH(0, 18, 10, 10),
      });
      expect(box('a'), isAbove(box('b'), gap: 8));
      expect(box('a'), isAbove(box('b'), minGap: 8, maxGap: 8));
      expect(box('a'), isAbove(box('b'), minGap: 4));
      expect(box('a'), isAbove(box('b'), maxGap: 12));
      expect(
        mismatch(box('a'), isAbove(box('b'), gap: 16)),
        contains('the gap is 8 px'),
      );
      expect(box('a'), isNot(isAbove(box('b'), maxGap: 4)));
      expect(box('a'), isNot(isAbove(box('b'), minGap: 10)));
    });

    testWidgets('tolerance absorbs rounding', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 10, 10.005),
        'b': const Rect.fromLTWH(0, 10, 10, 10),
      });
      expect(box('a'), isAbove(box('b')));
      expect(box('a'), isNot(isAbove(box('b'), tolerance: 0)));
    });

    test('describe', () {
      expect(
        describe(isAbove(find.text('B'), gap: 4)),
        'a widget above text "B" with a gap of 4 px',
      );
      expect(
        describe(isRightOf(find.text('B'), minGap: 2, maxGap: 6.5)),
        'a widget right of text "B" with a gap of 2 to 6.5 px',
      );
    });

    test('asserts on conflicting gaps', () {
      expect(
        () => isAbove(find.text('B'), gap: 4, minGap: 2),
        throwsAssertionError,
      );
      expect(
        () => isAbove(find.text('B'), minGap: 4, maxGap: 2),
        throwsAssertionError,
      );
    });
  });

  group('isAlignedWith', () {
    testWidgets('each edge', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(10, 10, 100, 20),
        'b': const Rect.fromLTWH(10, 50, 60, 40),
        'c': const Rect.fromLTWH(30, 0, 60, 40),
      });
      expect(box('a'), isAlignedWith(box('b'), edge: LayoutEdge.left));
      expect(box('a'), isAlignedWith(box('c'), edge: LayoutEdge.centerX));
      expect(box('a'), isAlignedWith(box('c'), edge: LayoutEdge.centerY));
      expect(
        box('b'),
        isAlignedWith(box('c'), edge: LayoutEdge.right, tolerance: 20),
      );
      expect(box('a'), isNot(isAlignedWith(box('b'), edge: LayoutEdge.top)));
      expect(
        mismatch(box('a'), isAlignedWith(box('c'), edge: LayoutEdge.left)),
        allOf(
          contains('left edge at 10'),
          contains('has it at 30'),
          contains('off by 20 px'),
        ),
      );
    });

    test('LayoutEdge.of', () {
      const Rect r = Rect.fromLTRB(1, 2, 5, 10);
      expect(LayoutEdge.values.map((LayoutEdge e) => e.of(r)), <double>[
        1,
        2,
        5,
        10,
        3,
        6,
      ]);
    });
  });

  group('overlaps / doesNotOverlap', () {
    testWidgets('detects overlap', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 50, 50),
        'b': const Rect.fromLTWH(40, 40, 50, 50),
        'touching': const Rect.fromLTWH(50, 0, 50, 50),
        'far': const Rect.fromLTWH(300, 300, 10, 10),
      });
      expect(box('a'), overlaps(box('b')));
      expect(box('a'), doesNotOverlap(box('touching')));
      expect(box('a'), doesNotOverlap(box('far')));
      expect(
        mismatch(box('a'), doesNotOverlap(box('b'))),
        contains(
          'overlaps key [<\'b\'>] at (40, 40, 90, 90) 50×50 by 10×10 px',
        ),
      );
      expect(
        mismatch(box('a'), overlaps(box('far'))),
        contains('does not overlap'),
      );
    });
  });

  group('isInside / isCenteredIn', () {
    testWidgets('containment with insets', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'card': const Rect.fromLTWH(0, 0, 200, 100),
        'label': const Rect.fromLTWH(16, 16, 100, 20),
        'wide': const Rect.fromLTWH(16, 16, 200, 20),
      });
      expect(box('label'), isInside(box('card')));
      expect(
        box('label'),
        isInside(box('card'), minInsets: const EdgeInsets.all(16)),
      );
      expect(
        box('label'),
        isNot(isInside(box('card'), minInsets: const EdgeInsets.all(20))),
      );
      expect(
        mismatch(box('wide'), isInside(box('card'))),
        contains(
          'sticks out of key [<\'card\'>] at (0, 0, 200, 100) 200×100 at the right by 16 px',
        ),
      );
    });

    testWidgets('centering per axis', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'outer': const Rect.fromLTWH(0, 0, 200, 100),
        'center': const Rect.fromLTWH(50, 25, 100, 50),
        'top': const Rect.fromLTWH(50, 0, 100, 50),
      });
      expect(box('center'), isCenteredIn(box('outer')));
      expect(box('top'), isCenteredIn(box('outer'), axis: Axis.horizontal));
      expect(box('top'), isNot(isCenteredIn(box('outer'))));
      expect(
        mismatch(box('top'), isCenteredIn(box('outer'))),
        contains('off center in'),
      );
      expect(
        mismatch(box('top'), isCenteredIn(box('outer'))),
        contains('25 px up'),
      );
    });
  });

  group('findsInOrder', () {
    testWidgets('a Column', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: <Widget>[Text('Name'), Text('Email'), Text('Submit')],
          ),
        ),
      );
      expect(<Finder>[
        find.text('Name'),
        find.text('Email'),
        find.text('Submit'),
      ], findsInOrder());
      expect(
        mismatch(<Finder>[
          find.text('Email'),
          find.text('Name'),
        ], findsInOrder()),
        allOf(
          contains('[1] text "Name"'),
          contains('is not below [0] text "Email"'),
        ),
      );
    });

    testWidgets('all four directions', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 10, 10),
        'b': const Rect.fromLTWH(20, 20, 10, 10),
        'c': const Rect.fromLTWH(40, 40, 10, 10),
      });
      final List<Finder> forward = <Finder>[box('a'), box('b'), box('c')];
      final List<Finder> backward = forward.reversed.toList();
      expect(forward, findsInOrder());
      expect(forward, findsInOrder(direction: AxisDirection.right));
      expect(backward, findsInOrder(direction: AxisDirection.up));
      expect(backward, findsInOrder(direction: AxisDirection.left));
      expect(backward, isNot(findsInOrder()));
      expect(forward, isNot(findsInOrder(direction: AxisDirection.left)));
    });

    testWidgets('allowOverlap compares leading edges', (
      WidgetTester tester,
    ) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 40, 40),
        'b': const Rect.fromLTWH(24, 0, 40, 40),
      });
      final List<Finder> avatars = <Finder>[box('a'), box('b')];
      expect(avatars, isNot(findsInOrder(direction: AxisDirection.right)));
      expect(
        avatars,
        findsInOrder(direction: AxisDirection.right, allowOverlap: true),
      );
      expect(
        mismatch(avatars, findsInOrder(direction: AxisDirection.right)),
        contains('starts 16 px too early'),
      );
    });

    testWidgets('reports which finder failed to resolve', (
      WidgetTester tester,
    ) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 10, 10),
      });
      expect(
        mismatch(<Finder>[box('a'), box('nope')], findsInOrder()),
        contains('[1] key [<\'nope\'>] found no widget'),
      );
      expect(
        mismatch(box('a'), findsInOrder()),
        contains('not a list of Finders'),
      );
      expect(mismatch(<Finder>[], findsInOrder()), contains('at least 1'));
    });

    testWidgets('works with a ListView after scrolling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ListView.builder(
            itemCount: 100,
            itemBuilder: (BuildContext context, int i) =>
                SizedBox(height: 50, child: Text('Item $i')),
          ),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pump();
      expect(<Finder>[
        find.text('Item 20'),
        find.text('Item 21'),
        find.text('Item 22'),
      ], findsInOrder());
      expect(find.text('Item 20'), isFullyVisible);
      expect(find.text('Item 19'), findsNothing);
      expect(find.text('Item 19', skipOffstage: false), isNotVisible);
    });
  });

  group('findsAligned / findsEvenlySpaced', () {
    testWidgets('aligned', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(16, 0, 100, 10),
        'b': const Rect.fromLTWH(16, 20, 50, 10),
        'c': const Rect.fromLTWH(18, 40, 50, 10),
      });
      expect(<Finder>[box('a'), box('b')], findsAligned(LayoutEdge.left));
      expect(
        mismatch(<Finder>[
          box('a'),
          box('b'),
          box('c'),
        ], findsAligned(LayoutEdge.left)),
        allOf(contains('[2] key'), contains('off by 2 px')),
      );
    });

    testWidgets('evenly spaced', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'a': const Rect.fromLTWH(0, 0, 10, 10),
        'b': const Rect.fromLTWH(0, 18, 10, 20),
        'c': const Rect.fromLTWH(0, 46, 10, 10),
        'd': const Rect.fromLTWH(0, 60, 10, 10),
        'e': const Rect.fromLTWH(18, 0, 10, 10),
      });
      expect(<Finder>[box('a'), box('b'), box('c')], findsEvenlySpaced());
      expect(<Finder>[box('a'), box('b'), box('c')], findsEvenlySpaced(gap: 8));
      expect(<Finder>[
        box('a'),
        box('e'),
      ], findsEvenlySpaced(axis: Axis.horizontal, gap: 8));
      expect(
        mismatch(<Finder>[
          box('a'),
          box('b'),
          box('c'),
          box('d'),
        ], findsEvenlySpaced()),
        allOf(
          contains('between [2] and [3] is 4 px, expected 8 px'),
          contains('gaps: 8, 8, 4'),
        ),
      );
      expect(
        mismatch(<Finder>[box('a')], findsEvenlySpaced()),
        contains('at least 2'),
      );
    });
  });

  group('visibility', () {
    testWidgets('screen edges', (WidgetTester tester) async {
      await pumpBoxes(tester, <String, Rect>{
        'in': const Rect.fromLTWH(0, 0, 100, 100),
        'half': const Rect.fromLTWH(750, 0, 100, 100),
        'out': const Rect.fromLTWH(0, 700, 100, 100),
      });
      expect(box('in'), isFullyVisible);
      expect(box('in'), isVisible);
      expect(box('half'), isVisible);
      expect(box('half'), isNot(isFullyVisible));
      expect(box('half'), isVisibleAtLeast(0.5));
      expect(box('half'), isNot(isVisibleAtLeast(0.6)));
      expect(box('out'), isNotVisible);
      expect(box('in'), isNot(isNotVisible));
      expect(
        mismatch(box('half'), isFullyVisible),
        contains('only 50% visible'),
      );
      expect(mismatch(box('out'), isVisible), contains('not visible at all'));
      expect(mismatch(box('in'), isNotVisible), contains('is 100% visible'));
    });

    testWidgets('scroll viewport clipping', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              SizedBox(
                height: 120,
                child: ListView(
                  children: <Widget>[
                    for (int i = 0; i < 5; i++)
                      SizedBox(height: 50, child: Text('Row $i')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Row 0'), isFullyVisible);
      expect(find.text('Row 2'), isVisible);
      expect(find.text('Row 2'), isNot(isFullyVisible));
      expect(find.text('Row 3', skipOffstage: false), isNotVisible);
    });

    testWidgets('zero-size widgets are never fully visible', (
      WidgetTester tester,
    ) async {
      await pumpBoxes(tester, <String, Rect>{'dot': Rect.zero});
      expect(box('dot'), isNot(isFullyVisible));
      expect(box('dot'), isNotVisible);
    });

    test('describe', () {
      expect(describe(isFullyVisible), 'a fully visible widget');
      expect(
        describe(isVisibleAtLeast(0.25)),
        'a widget with at least 25% of its area visible',
      );
      expect(() => isVisibleAtLeast(2), throwsAssertionError);
    });
  });

  testWidgets('expect() failures carry the message', (
    WidgetTester tester,
  ) async {
    await pumpBoxes(tester, <String, Rect>{
      'a': const Rect.fromLTWH(0, 40, 10, 10),
      'b': const Rect.fromLTWH(0, 0, 10, 10),
    });
    expect(
      () => expect(box('a'), isAbove(box('b'))),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains("Expected: a widget above key [<'b'>]"),
            contains("key [<'a'>] at (0, 40, 10, 50) 10×10 is not above"),
          ),
        ),
      ),
    );
  });
}
