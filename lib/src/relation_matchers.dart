import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'geometry.dart';
import 'layout_matcher.dart';

/// An edge or center line of a rectangle, used by [isAlignedWith] and
/// `findsAligned`.
enum LayoutEdge {
  /// The left edge.
  left,

  /// The top edge.
  top,

  /// The right edge.
  right,

  /// The bottom edge.
  bottom,

  /// The vertical line through the horizontal center.
  centerX,

  /// The horizontal line through the vertical center.
  centerY;

  /// The position of this edge of [rect], in the same coordinates as [rect].
  double of(Rect rect) => switch (this) {
    LayoutEdge.left => rect.left,
    LayoutEdge.top => rect.top,
    LayoutEdge.right => rect.right,
    LayoutEdge.bottom => rect.bottom,
    LayoutEdge.centerX => rect.center.dx,
    LayoutEdge.centerY => rect.center.dy,
  };

  /// A description for messages, such as `left edge` or `horizontal center`.
  String get label => switch (this) {
    LayoutEdge.left => 'left edge',
    LayoutEdge.top => 'top edge',
    LayoutEdge.right => 'right edge',
    LayoutEdge.bottom => 'bottom edge',
    LayoutEdge.centerX => 'horizontal center',
    LayoutEdge.centerY => 'vertical center',
  };
}

/// Matches a [Finder] whose widget is entirely above the widget found by
/// [other]: its bottom edge is at or above the other's top edge.
///
/// The widgets don't have to overlap horizontally.
///
/// Pass [gap] to require an exact distance between the two edges, or
/// [minGap] and/or [maxGap] for a range. Distances are in logical pixels and
/// compared with [tolerance].
///
/// ```dart
/// expect(find.text('Title'), isAbove(find.text('Subtitle'), gap: 4));
/// ```
Matcher isAbove(
  Finder other, {
  double? gap,
  double? minGap,
  double? maxGap,
  double tolerance = defaultLayoutTolerance,
}) => _SideMatcher(_Side.above, other, gap, minGap, maxGap, tolerance);

/// Matches a [Finder] whose widget is entirely below the widget found by
/// [other]: its top edge is at or below the other's bottom edge.
///
/// See [isAbove] for [gap], [minGap], [maxGap] and [tolerance].
Matcher isBelow(
  Finder other, {
  double? gap,
  double? minGap,
  double? maxGap,
  double tolerance = defaultLayoutTolerance,
}) => _SideMatcher(_Side.below, other, gap, minGap, maxGap, tolerance);

/// Matches a [Finder] whose widget is entirely to the left of the widget
/// found by [other]: its right edge is at or left of the other's left edge.
///
/// This is a screen direction. It doesn't flip for right-to-left text.
/// See [isAbove] for [gap], [minGap], [maxGap] and [tolerance].
Matcher isLeftOf(
  Finder other, {
  double? gap,
  double? minGap,
  double? maxGap,
  double tolerance = defaultLayoutTolerance,
}) => _SideMatcher(_Side.leftOf, other, gap, minGap, maxGap, tolerance);

/// Matches a [Finder] whose widget is entirely to the right of the widget
/// found by [other]: its left edge is at or right of the other's right edge.
///
/// This is a screen direction. It doesn't flip for right-to-left text.
/// See [isAbove] for [gap], [minGap], [maxGap] and [tolerance].
Matcher isRightOf(
  Finder other, {
  double? gap,
  double? minGap,
  double? maxGap,
  double tolerance = defaultLayoutTolerance,
}) => _SideMatcher(_Side.rightOf, other, gap, minGap, maxGap, tolerance);

/// Matches a [Finder] whose widget has the same [edge] as the widget found by
/// [other], within [tolerance] logical pixels.
///
/// ```dart
/// expect(find.text('Email'), isAlignedWith(find.text('Password'),
///     edge: LayoutEdge.left));
/// ```
Matcher isAlignedWith(
  Finder other, {
  required LayoutEdge edge,
  double tolerance = defaultLayoutTolerance,
}) => _AlignedMatcher(other, edge, tolerance);

/// Matches a [Finder] whose widget's rectangle overlaps the rectangle of the
/// widget found by [other].
///
/// Rectangles that only touch along an edge don't overlap. The overlap must be
/// wider and taller than [tolerance].
Matcher overlaps(Finder other, {double tolerance = defaultLayoutTolerance}) =>
    _OverlapMatcher(other, tolerance, expectOverlap: true);

/// Matches a [Finder] whose widget's rectangle doesn't overlap the rectangle
/// of the widget found by [other]. Touching edges are allowed.
///
/// See [overlaps] for [tolerance].
Matcher doesNotOverlap(
  Finder other, {
  double tolerance = defaultLayoutTolerance,
}) => _OverlapMatcher(other, tolerance, expectOverlap: false);

/// Matches a [Finder] whose widget lies entirely within the rectangle of the
/// widget found by [container], allowing [tolerance] logical pixels.
///
/// Pass [minInsets] to also require a minimum distance from each side of
/// the container, for example its padding.
Matcher isInside(
  Finder container, {
  EdgeInsets minInsets = EdgeInsets.zero,
  double tolerance = defaultLayoutTolerance,
}) => _InsideMatcher(container, minInsets, tolerance);

/// Matches a [Finder] whose widget is centered in the widget found by
/// [container].
///
/// By default both axes are checked. Pass [axis] to check only the
/// horizontal or only the vertical center.
Matcher isCenteredIn(
  Finder container, {
  Axis? axis,
  double tolerance = defaultLayoutTolerance,
}) => _CenteredMatcher(container, axis, tolerance);

enum _Side {
  above('above', 'bottom edge', 'top edge'),
  below('below', 'top edge', 'bottom edge'),
  leftOf('left of', 'right edge', 'left edge'),
  rightOf('right of', 'left edge', 'right edge');

  const _Side(this.word, this.ownEdge, this.otherEdge);

  final String word;
  final String ownEdge;
  final String otherEdge;

  /// The free space from [own] to [other] in this direction. Negative when
  /// the rectangles overlap or are on the wrong side.
  double space(Rect own, Rect other) => switch (this) {
    _Side.above => other.top - own.bottom,
    _Side.below => own.top - other.bottom,
    _Side.leftOf => other.left - own.right,
    _Side.rightOf => own.left - other.right,
  };
}

class _SideMatcher extends LayoutMatcher {
  _SideMatcher(
    this.side,
    this.other,
    this.gap,
    this.minGap,
    this.maxGap,
    this.tolerance,
  ) : assert(
        gap == null || (minGap == null && maxGap == null),
        'Pass either gap, or minGap/maxGap, not both.',
      ),
      assert(
        minGap == null || maxGap == null || minGap <= maxGap,
        'minGap must not be greater than maxGap.',
      );

  final _Side side;
  final Finder other;
  final double? gap;
  final double? minGap;
  final double? maxGap;
  final double tolerance;

  double get _lower => gap ?? minGap ?? 0;
  double get _upper => gap ?? maxGap ?? double.infinity;

  @override
  Description describe(Description description) {
    description.add('a widget ${side.word} ${describeFinder(other)}');
    if (gap != null) {
      description.add(' with a gap of ${formatPixels(gap!)} px');
    } else if (minGap != null && maxGap != null) {
      description.add(
        ' with a gap of ${formatPixels(minGap!)} to ${formatPixels(maxGap!)} px',
      );
    } else if (minGap != null) {
      description.add(' with a gap of at least ${formatPixels(minGap!)} px');
    } else if (maxGap != null) {
      description.add(' with a gap of at most ${formatPixels(maxGap!)} px');
    }
    return description;
  }

  @override
  String? check(Object? item) {
    final ResolvedBox own = resolveBox(asFinder(item));
    final ResolvedBox target = resolveBox(other);
    final double space = side.space(own.globalRect, target.globalRect);
    if (space >= _lower - tolerance && space <= _upper + tolerance) {
      return null;
    }
    final String where =
        '${describeBox(own)} is not ${side.word} ${describeBox(target)}';
    if (space < -tolerance && _lower <= 0) {
      return '$where: its ${side.ownEdge} is ${formatPixels(-space)} px past '
          'the other\'s ${side.otherEdge}';
    }
    return '$where with the expected gap: the gap is ${formatPixels(space)} px';
  }
}

class _AlignedMatcher extends LayoutMatcher {
  const _AlignedMatcher(this.other, this.edge, this.tolerance);

  final Finder other;
  final LayoutEdge edge;
  final double tolerance;

  @override
  Description describe(Description description) => description.add(
    'a widget whose ${edge.label} is aligned with ${describeFinder(other)}',
  );

  @override
  String? check(Object? item) {
    final ResolvedBox own = resolveBox(asFinder(item));
    final ResolvedBox target = resolveBox(other);
    final double a = edge.of(own.globalRect);
    final double b = edge.of(target.globalRect);
    if ((a - b).abs() <= tolerance) {
      return null;
    }
    return '${describeBox(own)} has its ${edge.label} at ${formatPixels(a)}, '
        'but ${describeBox(target)} has it at ${formatPixels(b)} '
        '(off by ${formatPixels((a - b).abs())} px)';
  }
}

class _OverlapMatcher extends LayoutMatcher {
  const _OverlapMatcher(
    this.other,
    this.tolerance, {
    required this.expectOverlap,
  });

  final Finder other;
  final double tolerance;
  final bool expectOverlap;

  @override
  Description describe(Description description) => description.add(
    expectOverlap
        ? 'a widget overlapping ${describeFinder(other)}'
        : 'a widget not overlapping ${describeFinder(other)}',
  );

  @override
  String? check(Object? item) {
    final ResolvedBox own = resolveBox(asFinder(item));
    final ResolvedBox target = resolveBox(other);
    final Rect overlap = own.globalRect.intersect(target.globalRect);
    final bool overlapping =
        overlap.width > tolerance && overlap.height > tolerance;
    if (overlapping == expectOverlap) {
      return null;
    }
    if (overlapping) {
      return '${describeBox(own)} overlaps ${describeBox(target)} by '
          '${formatPixels(overlap.width)}×${formatPixels(overlap.height)} px';
    }
    return '${describeBox(own)} does not overlap ${describeBox(target)}';
  }
}

class _InsideMatcher extends LayoutMatcher {
  const _InsideMatcher(this.container, this.minInsets, this.tolerance);

  final Finder container;
  final EdgeInsets minInsets;
  final double tolerance;

  @override
  Description describe(Description description) {
    description.add('a widget inside ${describeFinder(container)}');
    if (minInsets != EdgeInsets.zero) {
      description.add(' with insets of at least $minInsets');
    }
    return description;
  }

  @override
  String? check(Object? item) {
    final ResolvedBox own = resolveBox(asFinder(item));
    final ResolvedBox outer = resolveBox(container);
    final Rect inner = own.globalRect;
    final Rect bounds = minInsets.deflateRect(outer.globalRect);
    final List<String> problems = <String>[
      if (inner.left < bounds.left - tolerance)
        'left by ${formatPixels(bounds.left - inner.left)} px',
      if (inner.top < bounds.top - tolerance)
        'top by ${formatPixels(bounds.top - inner.top)} px',
      if (inner.right > bounds.right + tolerance)
        'right by ${formatPixels(inner.right - bounds.right)} px',
      if (inner.bottom > bounds.bottom + tolerance)
        'bottom by ${formatPixels(inner.bottom - bounds.bottom)} px',
    ];
    if (problems.isEmpty) {
      return null;
    }
    final String limit = minInsets == EdgeInsets.zero ? '' : ' (with insets)';
    return '${describeBox(own)} sticks out of ${describeBox(outer)}$limit at '
        'the ${problems.join(', ')}';
  }
}

class _CenteredMatcher extends LayoutMatcher {
  const _CenteredMatcher(this.container, this.axis, this.tolerance);

  final Finder container;
  final Axis? axis;
  final double tolerance;

  @override
  Description describe(Description description) {
    final String which = switch (axis) {
      null => '',
      Axis.horizontal => ' horizontally',
      Axis.vertical => ' vertically',
    };
    return description.add(
      'a widget centered$which in ${describeFinder(container)}',
    );
  }

  @override
  String? check(Object? item) {
    final ResolvedBox own = resolveBox(asFinder(item));
    final ResolvedBox outer = resolveBox(container);
    final Offset delta = own.globalRect.center - outer.globalRect.center;
    final List<String> problems = <String>[
      if (axis != Axis.vertical && delta.dx.abs() > tolerance)
        '${formatPixels(delta.dx.abs())} px ${delta.dx > 0 ? 'right' : 'left'}',
      if (axis != Axis.horizontal && delta.dy.abs() > tolerance)
        '${formatPixels(delta.dy.abs())} px ${delta.dy > 0 ? 'down' : 'up'}',
    ];
    if (problems.isEmpty) {
      return null;
    }
    return '${describeBox(own)} is off center in ${describeBox(outer)} by '
        '${problems.join(' and ')}';
  }
}
