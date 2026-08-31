import 'dart:math';

import '../../cards/card_deck.dart';
import '../../cards/info_card.dart';
import 'quiz_bank.dart';

/// Bir quiz sorusunun çoktan seçmeli gösterimi.
class QuizQuestion {
  const QuizQuestion({
    required this.card,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.isReview,
  });

  /// Sorunun kaynağı olan bilgi kartı.
  final InfoCard card;

  /// Ekranda gösterilen soru metni.
  final String questionText;

  /// Dört şık (A-D).
  final List<String> options;

  /// Doğru şıkkın [options] içindeki indeksi.
  final int correctIndex;

  /// Cevaptan sonra gösterilen açıklama — kartın kendi anlatımı.
  final String explanation;

  /// Kart albümde var mı? true ise soru bir tekrar/pekiştirme sorusudur,
  /// false ise oyuncunun henüz görmediği bir kartı öğretiyordur.
  final bool isReview;

  /// Doğru şıkkın metni.
  String get correctAnswer => options[correctIndex];
}

/// Tek bir quiz turunu yöneten motor.
///
/// Sorular [quizBank] içindeki elle yazılmış içerikten üretilir: her sorunun
/// tek bir doğru cevabı ve o soruya özel üç çeldiricisi vardır.
///
/// Soru seçimi **pekiştirmeye** göre yapılır: önce oyuncunun albümünde olan
/// ([collectedIds]) kartlar sorulur. Yeterli sayıda toplanmış kart yoksa kalan
/// sorular henüz toplanmamış kartlardan tamamlanır ki oyun her zaman
/// oynanabilsin — bu sorular [QuizQuestion.isReview] `false` ile işaretlenir.
class QuizEngine {
  QuizEngine({
    List<InfoCard>? deck,
    Set<String> collectedIds = const {},
    int questionCount = 10,
    Random? random,
  }) : _random = random ?? Random() {
    final source = deck ?? cardDeck;
    _questions = _generateQuestions(source, collectedIds, questionCount);
  }

  final Random _random;

  late final List<QuizQuestion> _questions;

  /// Toplam soru sayısı.
  int get questionCount => _questions.length;

  /// Bu turdaki sorulardan kaç tanesi albümdeki kartların tekrarı?
  int get reviewCount => _questions.where((q) => q.isReview).length;

  /// O anki sorunun indeksi (0-tabanlı).
  int _current = 0;
  int get currentIndex => _current;

  /// Doğru cevap sayısı.
  int _correctCount = 0;
  int get correctCount => _correctCount;

  /// Yanlış (ve süresi dolan) cevap sayısı.
  int get wrongCount => _current - _correctCount;

  /// Toplam puan.
  int _totalPoints = 0;
  int get totalPoints => _totalPoints;

  /// Son soruya ulaşıldı mı?
  bool get isFinished => _current >= _questions.length;

  /// Şu anki soru. [isFinished] true ise çağrılmamalı.
  QuizQuestion get currentQuestion => _questions[_current];

  /// Soru başına maksimum süre (saniye).
  static const int timePerQuestion = 30;

  /// Bir soruyu cevaplar.
  ///
  /// [selectedIndex] seçilen şıkkın indeksi, [remainingSeconds] kalan süre.
  /// Doğruysa kalan süre × 2 puan kazanılır. Yanlışsa 0.
  /// Dönen değer: doğru mu?
  bool answer(int selectedIndex, int remainingSeconds) {
    final correct = _questions[_current].correctIndex == selectedIndex;
    if (correct) {
      _correctCount++;
      _totalPoints += remainingSeconds * 2;
    }
    return correct;
  }

  /// Sonraki soruya geçer.
  void next() {
    if (_current < _questions.length) _current++;
  }

  /// Doğru oranına göre yıldız: %90+ → 3, %60+ → 2, %30+ → 1, altı → 0.
  ///
  /// Oran kullanılır çünkü soru sayısı destede kalan içeriğe göre 10'dan az
  /// olabilir.
  int get starsEarned {
    if (_questions.isEmpty) return 0;
    final ratio = _correctCount / _questions.length;
    if (ratio >= 0.9) return 3;
    if (ratio >= 0.6) return 2;
    if (ratio >= 0.3) return 1;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Soru üretimi
  // ---------------------------------------------------------------------------

  List<QuizQuestion> _generateQuestions(
    List<InfoCard> source,
    Set<String> collectedIds,
    int count,
  ) {
    // Yalnızca soru bankasında karşılığı olan kartlar sorulabilir.
    final askable = source.where((c) => quizBank.containsKey(c.id)).toList();

    final collected = askable.where((c) => collectedIds.contains(c.id)).toList()
      ..shuffle(_random);
    final rest = askable.where((c) => !collectedIds.contains(c.id)).toList()
      ..shuffle(_random);

    // Önce toplanan kartlar; eksik kalırsa geri kalanla tamamla.
    final selected = [...collected, ...rest].take(count).toList();

    return [
      for (final card in selected)
        _buildQuestion(card, isReview: collectedIds.contains(card.id)),
    ];
  }

  QuizQuestion _buildQuestion(InfoCard card, {required bool isReview}) {
    final item = quizBank[card.id]!;

    final options = [item.correctAnswer, ...item.distractors]
      ..shuffle(_random);

    return QuizQuestion(
      card: card,
      questionText: item.prompt,
      options: options,
      correctIndex: options.indexOf(item.correctAnswer),
      explanation: card.answer,
      isReview: isReview,
    );
  }
}
