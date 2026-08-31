import 'package:flutter/widgets.dart';

/// Uygulamadaki oyunlar. Ana sayfa listesi, istatistikler ve rozetler bu
/// kimlikleri paylaşır.
enum GameKind {
  tetris('Tetris'),
  sudoku('Sudoku'),
  blok('Blok Patlat'),
  quiz('Quiz');

  const GameKind(this.label);

  final String label;
}

/// Ödül ekranındaki küçük istatistik kutusu (ör. "Satır 12").
class GameStat {
  const GameStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

/// Bir oyun turunun sonucu; ödül ekranı bu özeti gösterir.
///
/// [stats] oyuna göre değişir: Sudoku seri/hata gösterirken Tetris satır ve
/// seviye gösterir. Süre her oyunda ortak olduğu için ayrı tutulur.
class GameSummary {
  const GameSummary({
    required this.kind,
    required this.points,
    required this.stars,
    required this.elapsed,
    this.stats = const [],
  });

  final GameKind kind;

  /// Ödül ekranındaki oyun adı.
  String get gameName => kind.label;

  final int points;

  /// Ana sayfadaki sayaca eklenecek yıldız.
  final int stars;

  final Duration elapsed;

  /// Oyuna özel istatistikler.
  final List<GameStat> stats;

  String get formattedTime {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
