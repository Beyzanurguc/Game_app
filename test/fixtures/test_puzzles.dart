import 'package:flutter/material.dart';
import 'package:game_app/games/yapboz/puzzle_catalog.dart';

/// Testler için yapboz listesi.
///
/// [PuzzlePicture.imageBytes] bilerek `null`: gerçek bir JPEG gömmek testleri
/// görsel çözmeye bağlardı. Baytsız durumda ekran yer tutucuyu çizer, widget
/// ağacı aynı kalır ve testler belirlenimci olur.
final List<PuzzlePicture> testPuzzles = [
  for (var index = 0; index < 4; index++)
    PuzzlePicture(
      id: 'yapboz_$index',
      title: 'Yapboz $index',
      imageBytes: null,
      accent: Colors.primaries[index].shade400,
      icon: Icons.extension_rounded,
      order: index,
    ),
];
