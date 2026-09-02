import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'info_card.dart';

/// Bilgi kartlarının kaynağı.
///
/// Kartlar uygulamada gömülü değil; Firestore'daki `cards` koleksiyonundan
/// gelir. Böylece konsoldan kart eklemek uygulama güncellemesi gerektirmez.
abstract interface class CardRepository {
  /// Bütün kartları sıralı olarak getirir.
  ///
  /// Bağlantı yoksa ya da koleksiyon boşsa boş liste döner — çağıran taraf
  /// bunu "içerik yok" durumu olarak gösterir.
  Future<List<InfoCard>> fetchCards();
}

/// Firestore `cards` koleksiyonunu okur.
class FirestoreCardRepository implements CardRepository {
  FirestoreCardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Koleksiyon adı — yükleme betiği (`tools/seed_firestore.js`) de bunu yazar.
  static const collectionName = 'cards';

  @override
  Future<List<InfoCard>> fetchCards() async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();

      final cards = [
        for (final doc in snapshot.docs) InfoCard.fromMap(doc.id, doc.data()),
      ];

      // Konsolda `order` boş bırakılmış kartlar 0 ile gelir; sıralamayı
      // kararlı tutmak için ikincil ölçüt başlık.
      cards.sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
      });

      // Başlıksız kart albümde boş kutu olarak görünürdü; onu hiç almayalım.
      return [
        for (final card in cards)
          if (card.title.isNotEmpty) card,
      ];
    } catch (error) {
      debugPrint('Kartlar okunamadı: $error');
      return const [];
    }
  }
}
