import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The default tolerance, in logical pixels, used when comparing edges.
///
/// Layout produces fractional offsets (for example when space is divided
/// evenly), so comparisons allow this much slack before reporting a mismatch.
const double defaultLayoutTolerance = 0.01;

/// Thrown when a finder can't be turned into a single on-screen rectangle.
///
/// The matchers in this package catch it and report [message] as the
/// mismatch, so tests fail with a readable explanation instead of a crash.
class LayoutResolutionException implements Exception {
  /// Creates an exception with the given [message].
  const LayoutResolutionException(this.message);

  /// Why the finder couldn't be resolved.
  final String message;

  @override
  String toString() => 'LayoutResolutionException: $message';
}

/// Returns the bounding rectangle, in global logical pixels, of the single
/// widget found by [finder].
///
/// The rectangle is the axis-aligned bounds of the widget's render box after
/// every ancestor transform (scrolling, [Transform], [FittedBox], ...) has
/// been applied. It ignores clipping; see [visibleRectOf] for that.
///
/// Throws a [LayoutResolutionException] if [finder] doesn't find exactly one
/// widget, or the widget has no laid-out [RenderBox].
Rect globalRectOf(Finder finder) => resolveBox(finder).globalRect;

/// Returns the part of [globalRectOf] that is actually visible: the widget's
/// bounds intersected with the screen and with every ancestor clip (scroll
/// viewports, [ClipRect], [ListView], ...).
///
/// Returns [Rect.zero] if nothing of the widget is visible.
///
/// This is a geometric check. It doesn't look at opacity, colors or widgets
/// painted on top.
///
/// Throws a [LayoutResolutionException] under the same conditions as
/// [globalRectOf].
Rect visibleRectOf(Finder finder) => resolveBox(finder).visibleRect;

/// A resolved render box together with a label for messages.
class ResolvedBox {
  ResolvedBox._(this.box, this.label);

  /// The widget's render box.
  final RenderBox box;

  /// A short description of the finder, for mismatch messages.
  final String label;

  /// See [globalRectOf].
  Rect get globalRect => MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );

  /// See [visibleRectOf].
  Rect get visibleRect {
    Rect visible = globalRect;
    RenderObject child = box;
    RenderObject? parent = child.parent;
    while (parent != null) {
      final Rect? clip = parent.describeApproximatePaintClip(child);
      if (clip != null) {
        visible = visible.intersect(
          MatrixUtils.transformRect(parent.getTransformTo(null), clip),
        );
      }
      child = parent;
      parent = child.parent;
    }
    if (child is RenderView) {
      visible = visible.intersect(Offset.zero & child.size);
    }
    if (visible.width <= 0 || visible.height <= 0) {
      return Rect.zero;
    }
    return visible;
  }
}

/// Resolves [finder] to exactly one laid-out render box.
///
/// This is the building block of every matcher in this package. It's public
/// so that custom matchers can report errors the same way.
///
/// Throws a [LayoutResolutionException] if [finder] doesn't find exactly one
/// widget, or the widget has no laid-out [RenderBox].
ResolvedBox resolveBox(Finder finder) {
  final String label = describeFinder(finder);
  final List<Element> elements = finder.evaluate().toList();
  if (elements.isEmpty) {
    throw LayoutResolutionException('$label found no widget');
  }
  if (elements.length > 1) {
    throw LayoutResolutionException(
      '$label found ${elements.length} widgets, expected exactly one '
      '(use .first, .last or .at(index) to pick one)',
    );
  }
  final RenderObject? renderObject = elements.single.renderObject;
  if (renderObject is! RenderBox) {
    throw LayoutResolutionException(
      '$label is not a box (${renderObject.runtimeType}), so it has no '
      'rectangle',
    );
  }
  if (!renderObject.hasSize || !renderObject.attached) {
    throw LayoutResolutionException('$label has not been laid out');
  }
  return ResolvedBox._(renderObject, label);
}

/// A short, human readable description of [finder], such as
/// `text "Save"` or `type "Icon"`.
String describeFinder(Finder finder) {
  const String prefix = 'widget with ';
  final String text = finder.describeMatch(Plurality.one);
  return text.startsWith(prefix) ? text.substring(prefix.length) : text;
}

/// Formats [value] with at most one decimal place, without a trailing `.0`.
String formatPixels(double value) {
  final String fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}

/// Formats [rect] as `(left, top, right, bottom) width×height`.
String formatRect(Rect rect) =>
    '(${formatPixels(rect.left)}, ${formatPixels(rect.top)}, '
    '${formatPixels(rect.right)}, ${formatPixels(rect.bottom)}) '
    '${formatPixels(rect.width)}×${formatPixels(rect.height)}';
