import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/card_deck.dart';
import 'package:game_app/games/quiz/quiz_bank.dart';
import 'package:game_app/games/quiz/quiz_screen.dart';

import 'helpers.dart';

/// Quiz ekranını, dört şıkkın tamamı ekrana sığacak bir görünümde açar.
Future<void> pumpQuiz(WidgetTester tester, {required int collected}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapApp(
      const QuizScreen(),
      collection: testCollection(collected: collected),
    ),
  );
  // Soru kartının kayarak girme animasyonunu tamamla (350 ms).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Ekranda görünen soruyu bankada bulur.
MapEntry<String, QuizItem> visibleItem(WidgetTester tester) {
  final match = quizBank.entries.where(
    (entry) => find.text(entry.value.prompt).evaluate().isNotEmpty,
  );
  expect(match, hasLength(1), reason: 'ekranda tam bir soru görünmeli');
  return match.first;
}

void main() {
  testWidgets('sorular oyuncunun topladığı kartlardan gelir', (tester) async {
    // Sadece ilk kart toplanmış olsun.
    await pumpQuiz(tester, collected: 1);

    final firstCard = cardDeck.first;
    expect(find.text(quizBank[firstCard.id]!.prompt), findsOneWidget);
    expect(find.text(firstCard.title), findsOneWidget);
    expect(find.text('Soru 1 / 10'), findsOneWidget);
  });

  testWidgets('şıklar o soruya ait dört seçenektir', (tester) async {
    await pumpQuiz(tester, collected: 1);

    final item = visibleItem(tester).value;
    expect(find.text(item.correctAnswer), findsOneWidget);
    for (final distractor in item.distractors) {
      expect(find.text(distractor), findsOneWidget);
    }
  });

  testWidgets('doğru şık seçilince puan yazılır ve açıklama gösterilir', (
    tester,
  ) async {
    await pumpQuiz(tester, collected: 1);

    final entry = visibleItem(tester);
    final card = cardDeck.firstWhere((c) => c.id == entry.key);

    await tester.tap(find.text(entry.value.correctAnswer));
    await tester.pump();
    await tester.tap(find.text('CEVABI KONTROL ET'));
    await tester.pump();

    expect(find.text('Harika, doğru cevap! 🎉'), findsOneWidget);
    expect(find.text(card.answer), findsOneWidget, reason: 'kartın anlatımı');
    expect(find.textContaining('Puan'), findsOneWidget);
    expect(find.text('SONRAKİ SORU'), findsOneWidget);

    // Puan sıfırdan büyük olmalı (kalan süre × 2).
    expect(find.text('0 Puan'), findsNothing);
  });

  testWidgets('yanlış şıkta doğru cevap gösterilir', (tester) async {
    await pumpQuiz(tester, collected: 1);

    final item = visibleItem(tester).value;

    await tester.tap(find.text(item.distractors.first));
    await tester.pump();
    await tester.tap(find.text('CEVABI KONTROL ET'));
    await tester.pump();

    expect(find.text('Doğru cevap:'), findsOneWidget);
    // Bir kez şıkta (yeşil işaretli), bir kez de geri bildirim kutusunda.
    expect(find.text(item.correctAnswer), findsNWidgets(2));
  });

  testWidgets('sonraki soru düğmesi yeni bir soru getirir', (tester) async {
    await pumpQuiz(tester, collected: 4);

    final first = visibleItem(tester).value;

    await tester.tap(find.text(first.correctAnswer));
    await tester.pump();
    await tester.tap(find.text('CEVABI KONTROL ET'));
    await tester.pump();
    await tester.tap(find.text('SONRAKİ SORU'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Soru 2 / 10'), findsOneWidget);
    expect(find.text(first.prompt), findsNothing);
    // Yeni soru da bankadan gelmeli.
    visibleItem(tester);
  });

  testWidgets('toplanmamış karttan gelen soru "yeni bilgi" olarak işaretlenir', (
    tester,
  ) async {
    // Hiç kart toplanmamış: tüm sorular yeni bilgi olmalı.
    await pumpQuiz(tester, collected: 0);

    expect(find.textContaining('yeni bilgi'), findsOneWidget);
  });
}
