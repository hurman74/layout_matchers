import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'geometry.dart';
import 'layout_matcher.dart';
import 'relation_matchers.dart';

/// Matches a list of [Finder]s whose widgets appear on screen in list order,
/// following [direction].
///
/// With the default [AxisDirection.down], each widget must start at or below
/// the bottom of the one before it. [AxisDirection.right] checks a row from
/// left to right, [AxisDirection.left] a right-to-left row, and
/// [AxisDirection.up] a list from the bottom up.
///
/// By default neighbors may not overlap. Set [allowOverlap] to only compare
/// leading edges, which suits overlapping cards or avatars.
///
/// Each finder must find exactly one widget.
///
/// ```dart
/// expect(
///   [find.text('Name'), find.text('Email'), find.text('Submit')],
///   findsInOrder(),
/// );
/// ```
Matcher findsInOrder({
  AxisDirection direction = AxisDirection.down,
  bool allowOverlap = false,
  double tolerance = defaultLayoutTolerance,
}) => _InOrderMatcher(direction, allowOverlap, tolerance);

/// Matches a list of [Finder]s whose widgets all share the same [edge],
/// within [tolerance] logical pixels.
///
/// ```dart
/// expect(
///   [find.text('Email'), find.byType(TextField), find.text('Forgot?')],
///   findsAligned(LayoutEdge.left),
/// );
/// ```
Matcher findsAligned(
  LayoutEdge edge, {
  double tolerance = defaultLayoutTolerance,
}) => _AlignedListMatcher(edge, tolerance);

/// Matches a list of [Finder]s whose widgets, taken in list order along
/// [axis], have the same free space between each neighbor.
///
/// Pass [gap] to also require that space to be a specific number of logical
/// pixels.
///
/// ```dart
/// final chips = find.byType(Chip);
/// expect(
///   [chips.at(0), chips.at(1), chips.at(2)],
///   findsEvenlySpaced(axis: Axis.horizontal, gap: 8),
/// );
/// ```
Matcher findsEvenlySpaced({
  Axis axis = Axis.vertical,
  double? gap,
  double tolerance = defaultLayoutTolerance,
}) => _EvenlySpacedMatcher(axis, gap, tolerance);

List<ResolvedBox> _resolveAll(Object? item, int minimum) {
  final List<Finder> finders = asFinderList(item);
  if (finders.length < minimum) {
    throw LayoutResolutionException(
      'has ${finders.length} finder(s), expected at least $minimum',
    );
  }
  return <ResolvedBox>[
    for (int i = 0; i < finders.length; i++) _resolveAt(finders[i], i),
  ];
}

ResolvedBox _resolveAt(Finder finder, int index) {
  try {
    return resolveBox(finder);
  } on LayoutResolutionException catch (error) {
    throw LayoutResolutionException('[$index] ${error.message}');
  }
}

String _at(ResolvedBox box, int index) => '[$index] ${describeBox(box)}';

class _InOrderMatcher extends LayoutMatcher {
  const _InOrderMatcher(this.direction, this.allowOverlap, this.tolerance);

  final AxisDirection direction;
  final bool allowOverlap;
  final double tolerance;

  String get _word => switch (direction) {
    AxisDirection.down => 'below',
    AxisDirection.up => 'above',
    AxisDirection.right => 'right of',
    AxisDirection.left => 'left of',
  };

  /// The position of [rect]'s leading and trailing edges along [direction],
  /// measured so that larger means further along.
  (double, double) _span(Rect rect) => switch (direction) {
    AxisDirection.down => (rect.top, rect.bottom),
    AxisDirection.up => (-rect.bottom, -rect.top),
    AxisDirection.right => (rect.left, rect.right),
    AxisDirection.left => (-rect.right, -rect.left),
  };

  @override
  Description describe(Description description) => description.add(
    'widgets in order, each ${allowOverlap ? 'starting ' : ''}'
    '$_word the previous one',
  );

  @override
  String? check(Object? item) {
    final List<ResolvedBox> boxes = _resolveAll(item, 1);
    for (int i = 1; i < boxes.length; i++) {
      final (double prevStart, double prevEnd) = _span(boxes[i - 1].globalRect);
      final (double start, _) = _span(boxes[i].globalRect);
      final double limit = allowOverlap ? prevStart : prevEnd;
      if (start < limit - tolerance) {
        return '${_at(boxes[i], i)} is not $_word ${_at(boxes[i - 1], i - 1)}: '
            'it starts ${formatPixels(limit - start)} px too early';
      }
    }
    return null;
  }
}

class _AlignedListMatcher extends LayoutMatcher {
  const _AlignedListMatcher(this.edge, this.tolerance);

  final LayoutEdge edge;
  final double tolerance;

  @override
  Description describe(Description description) =>
      description.add('widgets sharing the same ${edge.label}');

  @override
  String? check(Object? item) {
    final List<ResolvedBox> boxes = _resolveAll(item, 1);
    final double expected = edge.of(boxes.first.globalRect);
    for (int i = 1; i < boxes.length; i++) {
      final double actual = edge.of(boxes[i].globalRect);
      if ((actual - expected).abs() > tolerance) {
        return '${_at(boxes[i], i)} has its ${edge.label} at '
            '${formatPixels(actual)}, but ${_at(boxes.first, 0)} has it at '
            '${formatPixels(expected)} (off by '
            '${formatPixels((actual - expected).abs())} px)';
      }
    }
    return null;
  }
}

class _EvenlySpacedMatcher extends LayoutMatcher {
  const _EvenlySpacedMatcher(this.axis, this.gap, this.tolerance);

  final Axis axis;
  final double? gap;
  final double tolerance;

  @override
  Description describe(Description description) => description.add(
    gap == null
        ? 'evenly spaced widgets'
        : 'widgets spaced ${formatPixels(gap!)} px apart',
  );

  @override
  String? check(Object? item) {
    final List<ResolvedBox> boxes = _resolveAll(item, 2);
    final List<double> gaps = <double>[
      for (int i = 1; i < boxes.length; i++)
        axis == Axis.vertical
            ? boxes[i].globalRect.top - boxes[i - 1].globalRect.bottom
            : boxes[i].globalRect.left - boxes[i - 1].globalRect.right,
    ];
    final double expected = gap ?? gaps.first;
    for (int i = 0; i < gaps.length; i++) {
      if ((gaps[i] - expected).abs() > tolerance) {
        final String all = gaps.map(formatPixels).join(', ');
        return 'the gap between [$i] and [${i + 1}] is '
            '${formatPixels(gaps[i])} px, expected ${formatPixels(expected)} px '
            '(gaps: $all; [$i] ${describeBox(boxes[i])}, [${i + 1}] '
            '${describeBox(boxes[i + 1])})';
      }
    }
    return null;
  }
}
