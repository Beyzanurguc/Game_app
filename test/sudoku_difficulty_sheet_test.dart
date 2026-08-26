import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/home_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('zorluk sayfası kısa ekranda (390x844) taşmaz', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrapApp(const HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sudoku'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Zorluk seç'), findsOneWidget);
  });
}
