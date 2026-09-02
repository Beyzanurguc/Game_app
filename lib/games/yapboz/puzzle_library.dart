import 'package:flutter/widgets.dart';

import 'puzzle_catalog.dart';

/// Açılışta Firestore'dan okunan yapboz listesini widget ağacına dağıtır.
///
/// Kartlar [CardCollection] üzerinden aktığı için ayrı bir kapsam gerekmiyordu;
/// yapbozların sahibi yok, bu yüzden kendi kapsamı var.
class PuzzleLibraryScope extends InheritedWidget {
  const PuzzleLibraryScope({
    super.key,
    required this.pictures,
    required super.child,
  });

  /// Kullanılabilir yapbozlar. Boş liste "içerik yüklenemedi" demektir;
  /// yapboz ekranı buna göre bilgilendirme gösterir.
  final List<PuzzlePicture> pictures;

  static List<PuzzlePicture> of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PuzzleLibraryScope>();
    return scope?.pictures ?? const [];
  }

  @override
  bool updateShouldNotify(PuzzleLibraryScope oldWidget) =>
      !identical(oldWidget.pictures, pictures);
}
