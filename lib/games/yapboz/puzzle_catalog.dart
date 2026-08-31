import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Yapbozda kullanılabilecek bir resim.
///
/// Bilgi kartlarının [CardCategory] listesi burada kullanılmıyor: yapboz
/// resimleri kart konularıyla örtüşmek zorunda değil (çocuk, anne-kız, şehir
/// gibi konuların kart karşılığı yok). Onun yerine her resim kendi vurgu
/// rengini ve simgesini taşır.
class PuzzlePicture {
  const PuzzlePicture({
    required this.id,
    required this.title,
    required this.asset,
    required this.accent,
    required this.icon,
  });

  /// Kalıcı kimlik — testlerde ve kayıtta bu değer kullanılır.
  final String id;

  /// Resim seçme ekranında görünen ad.
  final String title;

  /// `pubspec.yaml` içinde kayıtlı asset yolu.
  ///
  /// Bu dosyalar `tools/prepare_puzzle_images.py` tarafından üretilir:
  /// `puzzle_sources/` altındaki orijinal ortadan kare kırpılır ve 1200×1200
  /// olarak buraya yazılır. Elle düzenlenmemeli.
  final String asset;

  /// Seçim kutusunda ve tahtadaki vurgularda kullanılan renk.
  final Color accent;

  /// Seçim kutusundaki küçük simge.
  final IconData icon;
}

/// Yapboz resimleri.
///
/// Yeni resim eklemek için:
///   1. Serbest lisanslı görseli `puzzle_sources/` altına **ASCII** bir adla
///      koy (ör. `kelebek.jpg`). Kare olması şart değil, kırpılır.
///   2. `python tools/prepare_puzzle_images.py` çalıştır.
///   3. Buraya bir satır ekle.
///
/// Buradaki her `asset` gerçekten var olmalı; `yapboz_screen_test.dart` bunu
/// doğrular.
const List<PuzzlePicture> puzzlePictures = [
  PuzzlePicture(
    id: 'kedi',
    title: 'Kedi',
    asset: 'assets/images/puzzles/kedi.jpg',
    accent: AppColors.foxOrange,
    icon: Icons.pets_rounded,
  ),
  PuzzlePicture(
    id: 'keci',
    title: 'Keçi',
    asset: 'assets/images/puzzles/keci.jpg',
    accent: AppColors.bandanaTeal,
    icon: Icons.pets_rounded,
  ),
  PuzzlePicture(
    id: 'salyangoz',
    title: 'Salyangoz',
    asset: 'assets/images/puzzles/salyangoz.jpg',
    accent: AppColors.secondary,
    icon: Icons.bug_report_rounded,
  ),
  PuzzlePicture(
    id: 'gezegen',
    title: 'Gezegen',
    asset: 'assets/images/puzzles/gezegen.jpg',
    accent: AppColors.plum,
    icon: Icons.rocket_launch_rounded,
  ),
  PuzzlePicture(
    id: 'gokkusagi',
    title: 'Gökkuşağı',
    asset: 'assets/images/puzzles/gokkusagi.jpg',
    accent: AppColors.leafGreen,
    icon: Icons.wb_sunny_rounded,
  ),

  PuzzlePicture(
    id: 'cocuk',
    title: 'Çocuk',
    asset: 'assets/images/puzzles/cocuk.jpg',
    accent: AppColors.tertiaryContainer,
    icon: Icons.emoji_emotions_rounded,
  ),
  PuzzlePicture(
    id: 'anne_kiz',
    title: 'Anne ve Kızı',
    asset: 'assets/images/puzzles/anne_kiz.jpg',
    accent: AppColors.berryPink,
    icon: Icons.favorite_rounded,
  ),
  PuzzlePicture(
    id: 'sehir',
    title: 'Şehir',
    asset: 'assets/images/puzzles/sehir.jpg',
    accent: AppColors.tertiary,
    icon: Icons.location_city_rounded,
  ),
];
