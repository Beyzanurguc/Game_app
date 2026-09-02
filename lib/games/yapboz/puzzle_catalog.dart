import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'puzzle_icons.dart';

/// Yapbozda kullanılan bir resim.
///
/// Görsel, yapboz belgesinin içinde Firestore'un `Bytes` alanı olarak durur —
/// Firebase Storage kullanılmıyor, çünkü Storage ücretli plan (Blaze)
/// gerektiriyor. 1200x1200 JPEG'ler 50–300 KB arasında; Firestore'un 1 MiB
/// belge sınırının epey altında kalıyorlar.
///
/// İleride Storage'a geçilirse yalnızca [PuzzleRepository] değişir; ekranlar
/// baytlarla çalıştığı için onlara dokunulmaz.
class PuzzlePicture {
  const PuzzlePicture({
    required this.id,
    required this.title,
    required this.imageBytes,
    required this.accent,
    required this.icon,
    this.order = 0,
  });

  /// Belge kimliği.
  final String id;

  /// Resim seçme ekranında görünen ad.
  final String title;

  /// JPEG verisi.
  ///
  /// `null` ise görsel okunamadı; ekran yer tutucu gösterir. Aynı yapbozun
  /// bütün parçaları **bu tek örneği** paylaşır: Flutter'ın görsel önbelleği
  /// [MemoryImage]'i bayt dizisinin kimliğine göre anahtarlıyor, yani yeni bir
  /// kopya üretmek 25 parçalık tahtada 25 kez çözme demek olurdu.
  final Uint8List? imageBytes;

  /// Seçim kutusunda ve tahtadaki vurgularda kullanılan renk.
  final Color accent;

  /// Seçim kutusundaki küçük simge.
  final IconData icon;

  /// Listeleme sırası.
  final int order;
}

/// Yapboz resimlerinin kaynağı.
abstract interface class PuzzleRepository {
  /// Yapbozları sıralı olarak getirir; hata durumunda boş liste döner.
  Future<List<PuzzlePicture>> fetchPuzzles();
}

/// Firestore `puzzles` koleksiyonu.
class FirestorePuzzleRepository implements PuzzleRepository {
  FirestorePuzzleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Koleksiyon adı — yükleme betiği de bunu yazar.
  static const collectionName = 'puzzles';

  /// Görselin belgedeki alan adı.
  static const imageField = 'image';

  @override
  Future<List<PuzzlePicture>> fetchPuzzles() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore.collection(collectionName).get();
    } catch (error) {
      debugPrint('Yapbozlar okunamadı: $error');
      return const [];
    }

    final pictures = <PuzzlePicture>[];
    for (final doc in snapshot.docs) {
      final picture = _toPicture(doc.id, doc.data());
      // Görseli olmayan yapbozu listeye almıyoruz: seçilebilir ama açılmayan
      // bir yapboz, listede hiç olmamasından daha kötü.
      if (picture != null) pictures.add(picture);
    }

    pictures.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
    });
    return pictures;
  }

  PuzzlePicture? _toPicture(String id, Map<String, dynamic> data) {
    final title = data['title'];
    if (title is! String || title.isEmpty) {
      debugPrint('$id: başlık yok, yapboz atlandı.');
      return null;
    }

    final image = data[imageField];
    if (image is! Blob || image.bytes.isEmpty) {
      debugPrint('$id: görsel alanı yok ya da boş, yapboz atlandı.');
      return null;
    }

    return PuzzlePicture(
      id: id,
      title: title,
      imageBytes: image.bytes,
      accent: data['accent'] is int
          ? Color(data['accent'] as int)
          : AppColors.foxOrange,
      icon: puzzleIconFor(data['icon']),
      order: data['order'] is int ? data['order'] as int : 0,
    );
  }
}
