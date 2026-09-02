import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bilgi kartı kategorileri. Albümdeki filtre çipleri bu sırayı kullanır.
///
/// Kategori Firestore'da [name] değeriyle (ör. `hayvanlar`) saklanır; renk ve
/// simge kodda kalır. Renk/simgeyi buluta taşımıyoruz çünkü `IconData`
/// çalışma anında üretilince Flutter'ın simge budaması (tree shaking) simgeyi
/// pakete koymuyor ve ekranda boş kare çıkıyor.
enum CardCategory {
  cevre('Çevre', Icons.eco_rounded, AppColors.leafGreen),
  hayvanlar('Hayvanlar', Icons.pets_rounded, AppColors.bandanaTeal),
  uzay('Uzay', Icons.rocket_launch_rounded, AppColors.tertiaryContainer),
  doga('Doğa', Icons.forest_rounded, AppColors.secondary),
  bilim('Bilim', Icons.science_rounded, AppColors.berryPink);

  const CardCategory(this.label, this.icon, this.accent);

  final String label;
  final IconData icon;

  /// Kartın çipinde ve görsel panelinde kullanılan renk.
  final Color accent;

  /// Firestore'daki metinden kategoriyi bulur.
  ///
  /// Tanınmayan değer kartı düşürmez; konsola yanlış yazılmış bir kategori
  /// yüzünden kart kaybolmasın diye [fallback] döner.
  static CardCategory fromName(
    Object? value, {
    CardCategory fallback = CardCategory.bilim,
  }) {
    for (final category in CardCategory.values) {
      if (category.name == value) return category;
    }
    return fallback;
  }
}

/// Bir bilgi kartına bağlı çoktan seçmeli quiz sorusu.
///
/// Soru kartın içinde durur: kart Firestore'a taşındığı için sorusu da orada
/// olmalı, yoksa konsoldan eklenen bir kart quizde hiç çıkmaz.
class QuizItem {
  const QuizItem({
    required this.prompt,
    required this.correctAnswer,
    required this.distractors,
  });

  /// Ekranda gösterilen soru metni.
  final String prompt;

  /// Tek doğru şık.
  final String correctAnswer;

  /// Üç yanlış şık. Hepsi soruya cevap olabilecek türden olmalı ki eleme
  /// mantıkla yapılabilsin.
  final List<String> distractors;

  /// Soru quizde sorulabilir mi?
  ///
  /// Eksik ya da yarım doldurulmuş bir soru quizi bozmasın diye motor bunu
  /// kontrol eder: dört şık olmalı ve hepsi birbirinden farklı olmalı.
  bool get isUsable =>
      prompt.trim().isNotEmpty &&
      correctAnswer.trim().isNotEmpty &&
      distractors.length == 3 &&
      distractors.every((option) => option.trim().isNotEmpty) &&
      {correctAnswer, ...distractors}.length == 4;

  Map<String, dynamic> toMap() => {
    'prompt': prompt,
    'correctAnswer': correctAnswer,
    'distractors': distractors,
  };

  static QuizItem? fromMap(Object? value) {
    if (value is! Map) return null;
    final map = value.cast<String, dynamic>();
    return QuizItem(
      prompt: _string(map['prompt']),
      correctAnswer: _string(map['correctAnswer']),
      distractors: _stringList(map['distractors']),
    );
  }
}

/// Oyun sonunda kazanılan ve albümde toplanan bilgi kartı.
class InfoCard {
  const InfoCard({
    required this.id,
    required this.title,
    required this.question,
    required this.answer,
    required this.facts,
    required this.category,
    required this.emoji,
    this.quiz,
    this.order = 0,
  });

  /// Kalıcı kimlik — koleksiyon bu değerle saklanır, Firestore'da da belge
  /// kimliğidir.
  final String id;

  /// Albümdeki kısa ad, ör. "Mavi Balina".
  final String title;

  /// Ödül ekranındaki başlık, ör. "Arılar neden altıgen seçer?".
  final String question;

  /// Sorunun kısa yanıtı.
  final String answer;

  /// "Biliyor muydun?" maddeleri.
  final List<String> facts;

  final CardCategory category;

  /// Görsel yerine kullanılan emoji.
  final String emoji;

  /// Kartın quiz sorusu. Yoksa kart quizde sorulmaz, albümde yine görünür.
  final QuizItem? quiz;

  /// Albümdeki sıralama. Firestore belgeleri sırasız geldiği için gerekli.
  final int order;

  Map<String, dynamic> toMap() => {
    'title': title,
    'question': question,
    'answer': answer,
    'facts': facts,
    'category': category.name,
    'emoji': emoji,
    'order': order,
    if (quiz != null) 'quiz': quiz!.toMap(),
  };

  /// Firestore belgesinden kart üretir.
  ///
  /// Eksik alanlar kartı düşürmez, boş değere düşer: konsolda yarım bırakılmış
  /// bir kart uygulamayı çökertmemeli.
  static InfoCard fromMap(String id, Map<String, dynamic> data) => InfoCard(
    id: id,
    title: _string(data['title']),
    question: _string(data['question']),
    answer: _string(data['answer']),
    facts: _stringList(data['facts']),
    category: CardCategory.fromName(data['category']),
    emoji: _string(data['emoji'], fallback: '❓'),
    quiz: QuizItem.fromMap(data['quiz']),
    order: data['order'] is int ? data['order'] as int : 0,
  );
}

String _string(Object? value, {String fallback = ''}) =>
    value is String && value.isNotEmpty ? value : fallback;

List<String> _stringList(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is String && item.trim().isNotEmpty) item,
      ]
    : const [];
