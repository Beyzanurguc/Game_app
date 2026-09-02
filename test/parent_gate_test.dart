import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/main.dart';
import 'package:game_app/settings/parent_gate.dart';

import 'helpers.dart';

/// Ana sayfayı telefon boyutunda açar.
Future<void> _pumpPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GameApp(collection: testCollection(), settings: testSettings()),
  );
}

/// Alt çubuktan ayarlara girmeyi dener; kapı ekranda kalır.
Future<void> _tapSettings(WidgetTester tester) async {
  await tester.tap(find.text('Ayarlar'));
  await tester.pumpAndSettle();
}

Finder get _question => find.byKey(const ValueKey('parent_gate_question'));
Finder get _answer => find.byKey(const ValueKey('parent_gate_answer'));
Finder get _submit => find.byKey(const ValueKey('parent_gate_submit'));
Finder get _cancel => find.byKey(const ValueKey('parent_gate_cancel'));

/// Ekranda duran sorunun doğru yanıtı.
int _correctAnswer(WidgetTester tester) {
  final text = tester.widget<Text>(_question).data ?? '';
  final numbers = RegExp(
    r'\d+',
  ).allMatches(text).map((match) => int.parse(match[0]!)).toList();
  return numbers[0] * numbers[1];
}

void main() {
  group('ParentGateQuestion', () {
    test('çarpanlar 6-9 aralığında kalır', () {
      final random = Random(7);

      for (var i = 0; i < 200; i++) {
        final question = ParentGateQuestion.generate(random);

        expect(question.first, inInclusiveRange(6, 9));
        expect(question.second, inInclusiveRange(6, 9));
        expect(question.answer, question.first * question.second);
        expect(question.text, '${question.first} × ${question.second}');
      }
    });

    test('avoid ile aynı yanıtlı soru üretilmez', () {
      final random = Random(3);
      var previous = ParentGateQuestion.generate(random);

      for (var i = 0; i < 200; i++) {
        final next = ParentGateQuestion.generate(random, avoid: previous);

        expect(next.answer, isNot(previous.answer));
        previous = next;
      }
    });
  });

  group('Yetişkin kapısı', () {
    testWidgets('ayarlar doğrudan açılmaz, önce soru sorulur', (tester) async {
      await _pumpPhone(tester);
      await _tapSettings(tester);

      expect(_question, findsOneWidget);
      // Ayarlar sayfasının kutuları henüz görünmemeli.
      expect(find.text('Günlük oyun hakkı'), findsNothing);
    });

    testWidgets('vazgeçilince ayarlar açılmaz', (tester) async {
      await _pumpPhone(tester);
      await _tapSettings(tester);

      await tester.tap(_cancel);
      await tester.pumpAndSettle();

      expect(_question, findsNothing);
      expect(find.text('Günlük oyun hakkı'), findsNothing);
      expect(find.text('Bugünün oyunları'), findsOneWidget);
    });

    testWidgets('yanlış yanıt içeri almaz ve soruyu değiştirir', (
      tester,
    ) async {
      await _pumpPhone(tester);
      await _tapSettings(tester);

      final before = tester.widget<Text>(_question).data;

      await tester.enterText(_answer, '${_correctAnswer(tester) + 1}');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(find.text('Günlük oyun hakkı'), findsNothing);
      expect(
        find.byKey(const ValueKey('parent_gate_error')),
        findsOneWidget,
        reason: 'yanlış yanıt kullanıcıya söylenmeli',
      );
      // Soru her denemede yenilenir; kutu da temizlenir.
      expect(tester.widget<Text>(_question).data, isNot(before));
      expect(tester.widget<TextField>(_answer).controller!.text, isEmpty);
    });

    testWidgets('yanlıştan sonra doğru yanıtla girilebilir', (tester) async {
      await _pumpPhone(tester);
      await _tapSettings(tester);

      await tester.enterText(_answer, '0');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      await passParentGate(tester);

      expect(find.text('Günlük oyun hakkı'), findsOneWidget);
    });

    testWidgets('doğru yanıt ayarlar sayfasını açar', (tester) async {
      await _pumpPhone(tester);
      await _tapSettings(tester);

      await passParentGate(tester);

      expect(_question, findsNothing);
      expect(find.text('İsim'), findsOneWidget);
      expect(find.text('Günlük oyun hakkı'), findsOneWidget);
    });
  });
}
