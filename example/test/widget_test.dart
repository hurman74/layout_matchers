import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_matchers/layout_matchers.dart';
import 'package:layout_matchers_example/main.dart';

Future<void> pumpPhone(WidgetTester tester, {double textScale = 1}) async {
  tester.view.physicalSize = const Size(360, 640) * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(const SignUpApp());
}

final Finder title = find.byKey(SignUpKeys.title);
final Finder subtitle = find.byKey(SignUpKeys.subtitle);
final Finder name = find.byKey(SignUpKeys.name);
final Finder email = find.byKey(SignUpKeys.email);
final Finder password = find.byKey(SignUpKeys.password);
final Finder confirm = find.byKey(SignUpKeys.confirm);
final Finder submit = find.byKey(SignUpKeys.submit);

void main() {
  testWidgets('the form reads top to bottom and lines up', (
    WidgetTester tester,
  ) async {
    await pumpPhone(tester);

    expect(<Finder>[
      title,
      subtitle,
      name,
      email,
      password,
      confirm,
      submit,
    ], findsInOrder());
    expect(title, isAbove(subtitle, gap: 8));
    expect(<Finder>[
      name,
      email,
      password,
      confirm,
    ], findsEvenlySpaced(gap: 16));
    expect(<Finder>[title, name, submit], findsAligned(LayoutEdge.left));
    expect(submit, isInside(find.byType(ListView)));
    expect(submit, isFullyVisible);
  });

  testWidgets('with large text the button needs a scroll', (
    WidgetTester tester,
  ) async {
    await pumpPhone(tester, textScale: 1.6);

    expect(<Finder>[title, subtitle, name, email], findsInOrder());
    expect(submit.hitTestable(), findsNothing);
    expect(find.byKey(SignUpKeys.submit, skipOffstage: false), isNotVisible);

    await tester.scrollUntilVisible(
      submit,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(submit, isFullyVisible);
  });
}
