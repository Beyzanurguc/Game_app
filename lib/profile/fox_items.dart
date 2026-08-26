import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tilkinin üzerinde aksesuar takılabilen bölgeler.
///
/// Her bölgede aynı anda tek bir aksesuar durur.
enum FoxSlot {
  hat('Şapka', Icons.emoji_events_rounded),
  glasses('Gözlük', Icons.remove_red_eye_rounded),
  neck('Boyun', Icons.checkroom_rounded);

  const FoxSlot(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Aksesuarın nasıl çizileceğini belirleyen biçim.
///
/// Çizim [FoxItemPainter] içinde bu değere göre yapılır; her biçim tilki
/// görselinin oranlarına göre yerleşir.
enum FoxShape {
  beanie,
  partyHat,
  topHat,
  crown,
  roundGlasses,
  sunglasses,
  heartGlasses,
  scarf,
  bowTie,
  medal,
}

/// Yıldızla alınan bir tilki aksesuarı.
class FoxItem {
  const FoxItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.shape,
    required this.price,
    required this.color,
    required this.accent,
  });

  /// Kalıcı kimlik — profil bu değerle saklanır.
  final String id;
  final String name;
  final FoxSlot slot;
  final FoxShape shape;

  /// Yıldız fiyatı.
  final int price;

  /// Aksesuarın ana rengi.
  final Color color;

  /// Şerit, taş, ponpon gibi ayrıntıların rengi.
  final Color accent;
}

/// Atölyedeki tüm aksesuarlar; fiyat sırasına yakın dizildi.
const foxItems = <FoxItem>[
  FoxItem(
    id: 'beanie',
    name: 'Yün Bere',
    slot: FoxSlot.hat,
    shape: FoxShape.beanie,
    price: 15,
    color: AppColors.bandanaTeal,
    accent: AppColors.creamBg,
  ),
  FoxItem(
    id: 'party_hat',
    name: 'Parti Şapkası',
    slot: FoxSlot.hat,
    shape: FoxShape.partyHat,
    price: 45,
    color: AppColors.berryPink,
    accent: AppColors.sunnyYellow,
  ),
  FoxItem(
    id: 'top_hat',
    name: 'Silindir Şapka',
    slot: FoxSlot.hat,
    shape: FoxShape.topHat,
    price: 75,
    color: AppColors.plum,
    accent: AppColors.sunnyYellow,
  ),
  FoxItem(
    id: 'crown',
    name: 'Altın Taç',
    slot: FoxSlot.hat,
    shape: FoxShape.crown,
    price: 120,
    color: AppColors.sunnyYellow,
    accent: AppColors.berryPink,
  ),
  FoxItem(
    id: 'round_glasses',
    name: 'Yuvarlak Gözlük',
    slot: FoxSlot.glasses,
    shape: FoxShape.roundGlasses,
    price: 30,
    color: AppColors.earthBrown,
    accent: Colors.white,
  ),
  FoxItem(
    id: 'sunglasses',
    name: 'Güneş Gözlüğü',
    slot: FoxSlot.glasses,
    shape: FoxShape.sunglasses,
    price: 55,
    color: Color(0xFF2E2A33),
    accent: AppColors.tertiaryContainer,
  ),
  FoxItem(
    id: 'heart_glasses',
    name: 'Kalp Gözlük',
    slot: FoxSlot.glasses,
    shape: FoxShape.heartGlasses,
    price: 90,
    color: AppColors.berryPink,
    accent: Colors.white,
  ),
  FoxItem(
    id: 'bow_tie',
    name: 'Papyon',
    slot: FoxSlot.neck,
    shape: FoxShape.bowTie,
    price: 20,
    color: AppColors.berryPink,
    accent: AppColors.creamBg,
  ),
  FoxItem(
    id: 'scarf',
    name: 'Çizgili Atkı',
    slot: FoxSlot.neck,
    shape: FoxShape.scarf,
    price: 35,
    color: AppColors.tertiary,
    accent: AppColors.sunnyYellow,
  ),
  FoxItem(
    id: 'medal',
    name: 'Altın Madalya',
    slot: FoxSlot.neck,
    shape: FoxShape.medal,
    price: 100,
    color: AppColors.sunnyYellow,
    accent: AppColors.tertiary,
  ),
];

/// Kimliğe göre aksesuar; bulunamazsa null.
FoxItem? foxItemById(String? id) {
  if (id == null) return null;
  for (final item in foxItems) {
    if (item.id == id) return item;
  }
  return null;
}

/// Bir bölgedeki aksesuarlar.
List<FoxItem> foxItemsFor(FoxSlot slot) =>
    foxItems.where((item) => item.slot == slot).toList();
