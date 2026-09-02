import 'package:flutter/material.dart';

/// Firestore'daki simge anahtarı -> simge.
///
/// Simge doğrudan kod noktası olarak saklanmıyor: Flutter yayın derlemesinde
/// kullanılmayan simgeleri fonttan atıyor (`--tree-shake-icons`) ve çalışma
/// anında üretilen bir `IconData` ekranda boş kare çıkıyor. Bu yüzden konsola
/// anahtar yazılır, karşılığı burada sabit durur.
///
/// Yeni bir anahtar eklemek uygulama güncellemesi gerektirir; tanınmayan
/// anahtar yapbozu düşürmez, [fallbackPuzzleIcon] kullanılır.
const Map<String, IconData> puzzleIcons = {
  'pets': Icons.pets_rounded,
  'bug': Icons.bug_report_rounded,
  'rocket': Icons.rocket_launch_rounded,
  'sun': Icons.wb_sunny_rounded,
  'smile': Icons.emoji_emotions_rounded,
  'heart': Icons.favorite_rounded,
  'city': Icons.location_city_rounded,
  'forest': Icons.park_rounded,
  'water': Icons.water_drop_rounded,
  'star': Icons.star_rounded,
  'image': Icons.image_rounded,
};

/// Anahtarı olmayan ya da tanınmayan yapbozun simgesi.
const IconData fallbackPuzzleIcon = Icons.extension_rounded;

IconData puzzleIconFor(Object? key) =>
    puzzleIcons[key] ?? fallbackPuzzleIcon;
