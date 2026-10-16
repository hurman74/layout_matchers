## 0.1.0

* Initial release.
* List matchers: `findsInOrder`, `findsAligned`, `findsEvenlySpaced`.
* Relation matchers: `isAbove`, `isBelow`, `isLeftOf`, `isRightOf` (with `gap`, `minGap`, `maxGap`),
  `isAlignedWith`, `overlaps`, `doesNotOverlap`, `isInside`, `isCenteredIn`.
* Visibility matchers that respect ancestor clips: `isFullyVisible`, `isVisible`, `isNotVisible`,
  `isVisibleAtLeast`.
* Helpers: `globalRectOf`, `visibleRectOf`, `resolveBox` and the `LayoutMatcher` base class.
