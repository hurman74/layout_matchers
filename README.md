# layout_matchers

Widget test matchers for where things end up on screen. Assert that widgets appear in order, sit above, below
or beside each other with a given gap, line up, don't overlap, stay inside their card, or are fully visible.
When a check fails, the message says where the widgets actually are.

![A sign-up form at text scale 1.0 to 1.6. Four layout checks run on each frame. Order, spacing and alignment keep passing, and isFullyVisible fails once the button is pushed below the screen edge.](https://raw.githubusercontent.com/hurman74/layout_matchers/main/doc/demo.gif)

## Install

It's only used in tests, so add it as a dev dependency:

```sh
flutter pub add dev:layout_matchers
```

## Usage

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_matchers/layout_matchers.dart';

testWidgets('sign-up form layout', (tester) async {
  await tester.pumpWidget(const SignUpApp());

  final title = find.text('Join in a minute');
  final name = find.byKey(SignUpKeys.name);
  final email = find.byKey(SignUpKeys.email);
  final submit = find.byKey(SignUpKeys.submit);

  // Reading order, top to bottom (or pass direction: AxisDirection.right).
  expect([title, name, email, submit], findsInOrder());

  // One widget relative to another, optionally with an exact gap or a range.
  expect(title, isAbove(name, minGap: 16));
  expect(find.byIcon(Icons.mail), isLeftOf(email, gap: 8));

  // Lining up, spacing, containment.
  expect([title, name, submit], findsAligned(LayoutEdge.left));
  expect([name, email], findsEvenlySpaced(gap: 16));
  expect(submit, isInside(find.byType(Card), minInsets: const EdgeInsets.all(16)));
  expect(find.byType(FloatingActionButton), doesNotOverlap(submit));

  // Clipped by the screen, a scroll view or a ClipRect?
  expect(submit, isFullyVisible);
});
```

### All matchers

| Matcher | Applies to | Passes when |
|---|---|---|
| `findsInOrder({direction, allowOverlap})` | `List<Finder>` | each widget starts after the previous one ends (`down`, `up`, `right` or `left`) |
| `findsAligned(edge)` | `List<Finder>` | all widgets share a `LayoutEdge` (`left`, `top`, `right`, `bottom`, `centerX`, `centerY`) |
| `findsEvenlySpaced({axis, gap})` | `List<Finder>` | the space between neighbors is equal (and equals `gap`, if given) |
| `isAbove`, `isBelow`, `isLeftOf`, `isRightOf` | `Finder` | the widget is entirely on that side of `other`, with an optional `gap`, `minGap` or `maxGap` |
| `isAlignedWith(other, edge:)` | `Finder` | both widgets share the edge |
| `overlaps(other)`, `doesNotOverlap(other)` | `Finder` | the rectangles do (or don't) intersect; touching edges don't count |
| `isInside(container, {minInsets})` | `Finder` | the widget is within the container, optionally keeping a minimum inset |
| `isCenteredIn(container, {axis})` | `Finder` | the centers match, on both axes or one |
| `isFullyVisible`, `isVisible`, `isNotVisible`, `isVisibleAtLeast(f)` | `Finder` | how much of the widget survives clipping by the screen and its ancestors |

Every matcher takes a `tolerance` in logical pixels (default 0.01). Each finder must find exactly one widget; use
`.first`, `.last` or `.at(i)` if it finds more. `globalRectOf(finder)` and `visibleRectOf(finder)` give you the
rectangles directly, and `LayoutMatcher` is the base class if you want to write your own matcher that fails the same way.

## Why this package

`flutter_test` can find widgets but can't say where they are relative to each other. The usual workaround is
`tester.getRect` plus arithmetic and `isTrue`. It's verbose, it ignores clipping, and when it fails you get
`Expected: true, Actual: <false>`:

![Side by side, the same failing check at 1.6x text. getRect with isTrue prints Expected true, Actual false. isFullyVisible prints the button's rectangle and says it is only 52.1% visible.](https://raw.githubusercontent.com/hurman74/layout_matchers/main/doc/comparison.png)

The Flutter team asked for this as a package. The framework PR adding an ordered-widgets matcher was closed
in favor of one ([flutter/flutter#167071](https://github.com/flutter/flutter/issues/167071)). These matchers
cover order and the other layout checks people usually write by hand:

- **Readable failures.** Messages name the finder, its rectangle and the exact number of pixels it's off by.
- **Clip-aware visibility.** `isFullyVisible` follows every ancestor clip (scroll viewports, `ClipRect`,
  the screen edge), so it catches a button pushed below the fold or cut off by a fixed-height box.
- **Real geometry.** Rectangles go through every transform (`Transform`, `FittedBox`, scrolling), the same way
  hit testing does.
- **No dependencies** beyond `flutter_test`.

![The same form at 1.6x text scale. Order, spacing and alignment pass, while isFullyVisible fails and shows the visible part of the button.](https://raw.githubusercontent.com/hurman74/layout_matchers/main/doc/large_text.png)

## Limitations

- Visibility is geometric only. A widget under `Opacity(opacity: 0)` or covered by another widget, such as content
  scrolled under a pinned `SliverAppBar`, still counts as visible. To check that it's covered, use `finder.hitTestable()`.
- Widgets that a scroll view keeps just outside its viewport are skipped by finders by default. Use
  `find.byKey(key, skipOffstage: false)` with `isNotVisible`. Lazy lists don't build far-away items at all, so use
  `findsNothing` for those.
- Rotated widgets are compared by their axis-aligned bounding box.
- Only box widgets have a rectangle. A finder that matches a sliver fails with a message saying so; find a box
  inside it instead.
- `isLeftOf` and `isRightOf` are screen directions. They don't flip for right-to-left text. For RTL reading order,
  use `findsInOrder(direction: AxisDirection.left)`.
