import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/card_deck.dart';
import 'package:game_app/games/quiz/quiz_bank.dart';
import 'package:game_app/games/quiz/quiz_engine.dart';

void main() {
  group('quizBank', () {
    test('destedeki her kartın bir sorusu var', () {
      final missing = cardDeck
          .where((card) => !quizBank.containsKey(card.id))
          .map((card) => card.id)
          .toList();
      expect(missing, isEmpty, reason: 'soru bankasında eksik kart(lar)');
    });

    test('bankada destede olmayan kimlik yok', () {
      final deckIds = cardDeck.map((c) => c.id).toSet();
      expect(quizBank.keys.where((id) => !deckIds.contains(id)), isEmpty);
    });

    test('her sorunun üç farklı çeldiricisi var', () {
      for (final entry in quizBank.entries) {
        final item = entry.value;
        expect(
          item.distractors.length,
          3,
          reason: '${entry.key}: çeldirici sayısı 3 olmalı',
        );
        expect(
          {item.correctAnswer, ...item.distractors}.length,
          4,
          reason: '${entry.key}: şıklar birbirinin aynısı olmamalı',
        );
      }
    });

    test('soru ve şık metinleri boş değil', () {
      for (final entry in quizBank.entries) {
        final item = entry.value;
        expect(item.prompt.trim(), isNotEmpty, reason: entry.key);
        expect(item.correctAnswer.trim(), isNotEmpty, reason: entry.key);
        for (final d in item.distractors) {
          expect(d.trim(), isNotEmpty, reason: entry.key);
        }
      }
    });
  });

  group('QuizEngine', () {
    test('her soruda dört şık ve geçerli bir doğru indeks var', () {
      final engine = QuizEngine(random: Random(7));
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

    test('doğru şık, kartın soru bankasındaki cevabıdır', () {
      final engine = QuizEngine(random: Random(3));
      for (var i = 0; i < engine.questionCount; i++) {
        final q = engine.currentQuestion;
        final item = quizBank[q.card.id]!;
        expect(q.questionText, item.prompt);
        expect(q.correctAnswer, item.correctAnswer);
        // Yanlış şıklar o soruya özel çeldiriciler olmalı, rastgele başlıklar
        // değil.
        final wrong = [...q.options]..remove(item.correctAnswer);
        expect(wrong.toSet(), item.distractors.toSet());
        engine.next();
      }
    });

    test('sorular önce toplanmış kartlardan seçilir', () {
      final collected = cardDeck.take(10).map((c) => c.id).toSet();
      final engine = QuizEngine(collectedIds: collected, random: Random(1));

      expect(engine.questionCount, 10);
      expect(engine.reviewCount, 10);
      for (var i = 0; i < engine.questionCount; i++) {
        expect(collected, contains(engine.currentQuestion.card.id));
        expect(engine.currentQuestion.isReview, isTrue);
        engine.next();
      }
    });

    test('toplanan kart azsa kalan sorular desteden tamamlanır', () {
      final collected = cardDeck.take(3).map((c) => c.id).toSet();
      final engine = QuizEngine(collectedIds: collected, random: Random(2));

      expect(engine.questionCount, 10);
      expect(engine.reviewCount, 3);
    });

    test('hiç kart toplanmamışsa oyun yine de oynanabilir', () {
      final engine = QuizEngine(random: Random(5));
      expect(engine.questionCount, 10);
      expect(engine.reviewCount, 0);
    });

    test('doğru cevap kalan sürenin iki katı puan verir', () {
      final engine = QuizEngine(random: Random(11));
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
        final engine = QuizEngine(random: Random(4));
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
      final engine = QuizEngine(deck: cardDeck.take(4).toList(), random: Random(1));
      expect(engine.questionCount, 4);
    });
  });
}
