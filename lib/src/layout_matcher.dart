import 'package:flutter_test/flutter_test.dart';

import 'geometry.dart';

/// Base class for the matchers in this package.
///
/// Subclasses implement [check], which returns `null` when the item matches
/// and a sentence explaining the mismatch otherwise. Any
/// [LayoutResolutionException] thrown while resolving finders is reported as
/// the mismatch.
abstract class LayoutMatcher extends Matcher {
  /// Const constructor for subclasses.
  const LayoutMatcher();

  /// Returns `null` if [item] matches, or the reason it doesn't.
  String? check(Object? item);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    String? reason;
    try {
      reason = check(item);
    } on LayoutResolutionException catch (error) {
      reason = error.message;
    }
    if (reason == null) {
      return true;
    }
    matchState[LayoutMatcher] = reason;
    return false;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    final Object? reason = matchState[LayoutMatcher];
    return mismatchDescription.add(reason is String ? reason : 'did not match');
  }
}

/// Casts [item] to a finder, or throws a [LayoutResolutionException].
Finder asFinder(Object? item) {
  if (item is Finder) {
    return item;
  }
  throw LayoutResolutionException(
    'is a ${item.runtimeType}, not a Finder (pass find.xyz(...))',
  );
}

/// Casts [item] to a list of finders, or throws a
/// [LayoutResolutionException].
List<Finder> asFinderList(Object? item) {
  if (item is Iterable && item.every((Object? e) => e is Finder)) {
    return item.cast<Finder>().toList();
  }
  throw LayoutResolutionException(
    'is a ${item.runtimeType}, not a list of Finders',
  );
}

/// Describes a resolved box as `label at (l, t, r, b) w×h`.
String describeBox(ResolvedBox box) =>
    '${box.label} at ${formatRect(box.globalRect)}';
