import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/quiz/quiz_engine.dart';

import 'fixtures/test_cards.dart';

void main() {
  group('soru kaynağı', () {
    test('sorular kartın kendi quiz alanından üretilir', () {
      final engine = QuizEngine(deck: testDeck, random: Random(3));

      for (var i = 0; i < engine.questionCount; i++) {
        final q = engine.currentQuestion;
        final item = q.card.quiz!;
        expect(q.questionText, item.prompt);
        expect(q.correctAnswer, item.correctAnswer);
        // Yanlış şıklar o soruya özel çeldiriciler olmalı.
        final wrong = [...q.options]..remove(item.correctAnswer);
        expect(wrong.toSet(), item.distractors.toSet());
        engine.next();
      }
    });

    test('quiz sorusu olmayan kart sorulmaz', () {
      // Firestore'a sorusuz bir kart eklenirse quiz bozulmamalı.
      final deck = [...testDeck.take(5), cardWithoutQuiz('sorusuz')];
      final engine = QuizEngine(deck: deck, random: Random(1));

      expect(engine.questionCount, 5);
      for (var i = 0; i < engine.questionCount; i++) {
        expect(engine.currentQuestion.card.id, isNot('sorusuz'));
        engine.next();
      }
    });

    test('şıkları eksik kart sorulmaz', () {
      final deck = [...testDeck.take(5), cardWithBrokenQuiz('bozuk')];
      final engine = QuizEngine(deck: deck, random: Random(1));

      expect(engine.questionCount, 5);
    });

    test('hiç sorulabilir kart yoksa tur boş kalır', () {
      final engine = QuizEngine(
        deck: [cardWithoutQuiz('a'), cardWithBrokenQuiz('b')],
        random: Random(1),
      );

      expect(engine.questionCount, 0);
      expect(engine.isFinished, isTrue);
      expect(engine.starsEarned, 0);
    });
  });

  group('QuizEngine', () {
    test('her soruda dört şık ve geçerli bir doğru indeks var', () {
      final engine = QuizEngine(deck: testDeck, random: Random(7));
      expect(engine.questionCount, 10);

      for (var i = 0; i < engine.questionCount; i++) {
        final q = engine.currentQuestion;
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4, reason: 'şıklar tekrar etmemeli');
        expect(q.correctIndex, inInclusiveRange(0, 3));
        engine.next();
      }
      expect(engine.isFinished, isTrue);
    });

    test('sorular önce toplanmış kartlardan seçilir', () {
      final collected = testDeck.take(10).map((c) => c.id).toSet();
      final engine = QuizEngine(deck: testDeck, collectedIds: collected, random: Random(1));

      expect(engine.questionCount, 10);
      expect(engine.reviewCount, 10);
      for (var i = 0; i < engine.questionCount; i++) {
        expect(collected, contains(engine.currentQuestion.card.id));
        expect(engine.currentQuestion.isReview, isTrue);
        engine.next();
      }
    });

    test('toplanan kart azsa kalan sorular desteden tamamlanır', () {
      final collected = testDeck.take(3).map((c) => c.id).toSet();
      final engine = QuizEngine(deck: testDeck, collectedIds: collected, random: Random(2));

      expect(engine.questionCount, 10);
      expect(engine.reviewCount, 3);
    });

    test('hiç kart toplanmamışsa oyun yine de oynanabilir', () {
      final engine = QuizEngine(deck: testDeck, random: Random(5));
      expect(engine.questionCount, 10);
      expect(engine.reviewCount, 0);
    });

    test('doğru cevap kalan sürenin iki katı puan verir', () {
      final engine = QuizEngine(deck: testDeck, random: Random(11));
      final q = engine.currentQuestion;

      expect(engine.answer(q.correctIndex, 20), isTrue);
      expect(engine.correctCount, 1);
      expect(engine.totalPoints, 40);

      engine.next();
      final wrongIndex = (engine.currentQuestion.correctIndex + 1) % 4;
      expect(engine.answer(wrongIndex, 20), isFalse);
      expect(engine.correctCount, 1);
      expect(engine.totalPoints, 40);
    });

    test('yıldızlar doğru oranına göre verilir', () {
      int starsFor(int correct) {
        final engine = QuizEngine(deck: testDeck, random: Random(4));
        for (var i = 0; i < engine.questionCount; i++) {
          final q = engine.currentQuestion;
          final index = i < correct
              ? q.correctIndex
              : (q.correctIndex + 1) % 4;
          engine.answer(index, 10);
          engine.next();
        }
        return engine.starsEarned;
      }

      expect(starsFor(10), 3);
      expect(starsFor(9), 3);
      expect(starsFor(8), 2);
      expect(starsFor(6), 2);
      expect(starsFor(5), 1);
      expect(starsFor(3), 1);
      expect(starsFor(2), 0);
      expect(starsFor(0), 0);
    });

    test('deste soru sayısından küçükse soru sayısı destede sınırlanır', () {
      final engine = QuizEngine(deck: testDeck.take(4).toList(), random: Random(1));
      expect(engine.questionCount, 4);
    });
  });
}
