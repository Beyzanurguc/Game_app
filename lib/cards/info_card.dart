import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bilgi kartı kategorileri. Albümdeki filtre çipleri bu sırayı kullanır.
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
  });

  /// Kalıcı kimlik — koleksiyon bu değerle saklanır.
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
  ///
  /// TODO: Karta özel çizim eklendiğinde asset yoluna geçilecek.
  final String emoji;
}
