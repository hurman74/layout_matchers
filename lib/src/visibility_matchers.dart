import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';

import 'geometry.dart';
import 'layout_matcher.dart';

/// Matches a [Finder] whose widget is entirely visible: not cut off by the
/// edge of the screen, a scroll view, or any other clip.
///
/// This checks geometry only. A widget hidden by `Opacity` or covered by
/// another widget still counts as visible.
///
/// ```dart
/// await tester.pumpWidget(app);
/// expect(find.text('Submit'), isFullyVisible);
/// ```
const Matcher isFullyVisible = _VisibilityMatcher(_Visibility.full);

/// Matches a [Finder] whose widget has at least some visible area on screen.
///
/// See [isFullyVisible] for what counts as visible.
const Matcher isVisible = _VisibilityMatcher(_Visibility.some);

/// Matches a [Finder] whose widget is laid out but has no visible area: it's
/// scrolled out of view, off screen or clipped away.
///
/// Unlike `findsNothing`, the widget must still exist. Finders skip widgets
/// that a scroll view keeps built just outside its viewport, so pass
/// `skipOffstage: false` to reach them:
///
/// ```dart
/// expect(find.text('Row 3', skipOffstage: false), isNotVisible);
/// ```
///
/// Lazy lists don't build items far off screen at all; use `findsNothing`
/// for those.
const Matcher isNotVisible = _VisibilityMatcher(_Visibility.none);

/// Matches a [Finder] whose widget has at least [fraction] (0 to 1) of its
/// area visible.
///
/// ```dart
/// expect(find.byKey(const Key('banner')), isVisibleAtLeast(0.5));
/// ```
Matcher isVisibleAtLeast(double fraction) {
  assert(fraction >= 0 && fraction <= 1, 'fraction must be between 0 and 1');
  return _VisibilityMatcher(_Visibility.fraction, fraction);
}

enum _Visibility { full, some, none, fraction }

class _VisibilityMatcher extends LayoutMatcher {
  const _VisibilityMatcher(this.kind, [this.fraction = 0]);

  final _Visibility kind;
  final double fraction;

  @override
  Description describe(Description description) =>
      description.add(switch (kind) {
        _Visibility.full => 'a fully visible widget',
        _Visibility.some => 'a widget that is at least partly visible',
        _Visibility.none => 'a widget with no visible area',
        _Visibility.fraction =>
          'a widget with at least ${_percent(fraction)} of its area visible',
      });

  @override
  String? check(Object? item) {
    final ResolvedBox box = resolveBox(asFinder(item));
    final Rect full = box.globalRect;
    final Rect visible = box.visibleRect;
    final double area = full.width * full.height;
    final double shown = area <= 0
        ? 0
        : (visible.width * visible.height / area).clamp(0.0, 1.0);
    final bool ok = switch (kind) {
      _Visibility.full =>
        (visible.left - full.left).abs() <= defaultLayoutTolerance &&
            (visible.top - full.top).abs() <= defaultLayoutTolerance &&
            (visible.right - full.right).abs() <= defaultLayoutTolerance &&
            (visible.bottom - full.bottom).abs() <= defaultLayoutTolerance &&
            area > 0,
      _Visibility.some => visible != Rect.zero,
      _Visibility.none => visible == Rect.zero,
      _Visibility.fraction => shown >= fraction - 1e-9 && area > 0,
    };
    if (ok) {
      return null;
    }
    if (kind == _Visibility.none) {
      return '${describeBox(box)} is ${_percent(shown)} visible: '
          'the visible part is ${formatRect(visible)}';
    }
    if (visible == Rect.zero) {
      return '${describeBox(box)} is not visible at all';
    }
    return '${describeBox(box)} is only ${_percent(shown)} visible: '
        'the visible part is ${formatRect(visible)}';
  }
}

String _percent(double fraction) => '${formatPixels(fraction * 100)}%';
