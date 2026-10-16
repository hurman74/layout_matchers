/// Widget test matchers for where widgets end up on screen.
///
/// Use them with `expect` in `testWidgets`, after pumping:
///
/// ```dart
/// expect(
///   [find.text('Name'), find.text('Email'), find.text('Submit')],
///   findsInOrder(),
/// );
/// expect(find.text('Title'), isAbove(find.text('Subtitle'), gap: 4));
/// expect(find.text('Submit'), isFullyVisible);
/// ```
///
/// Every matcher resolves each finder to exactly one widget and compares
/// global rectangles in logical pixels. Mismatch messages include the
/// rectangles, so a failing test says where things actually are.
library;

export 'src/geometry.dart'
    show
        LayoutResolutionException,
        ResolvedBox,
        defaultLayoutTolerance,
        describeFinder,
        formatRect,
        globalRectOf,
        resolveBox,
        visibleRectOf;
export 'src/layout_matcher.dart' show LayoutMatcher;
export 'src/list_matchers.dart'
    show findsAligned, findsEvenlySpaced, findsInOrder;
export 'src/relation_matchers.dart'
    show
        LayoutEdge,
        doesNotOverlap,
        isAbove,
        isAlignedWith,
        isBelow,
        isCenteredIn,
        isInside,
        isLeftOf,
        isRightOf,
        overlaps;
export 'src/visibility_matchers.dart'
    show isFullyVisible, isNotVisible, isVisible, isVisibleAtLeast;
