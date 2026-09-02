import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../cards/card_storage.dart';
import '../profile/profile_storage.dart';

/// Oyuncu ilerlemesinin Firestore'daki yeri: `users/{uid}`.
///
/// Koleksiyon ve profil aynı belgede ama ayrı alanlarda tutulur
/// (`collection` ve `profile`). Her depo yalnızca kendi alanını `merge` ile
/// yazdığı için birbirlerinin verisini ezmezler ve kullanıcı başına tek belge
/// okunur.
const _usersCollection = 'users';
const _collectionField = 'collection';
const _profileField = 'profile';

/// Toplanan kartların ve yıldızların bulut kaydı.
///
/// [local] verilirse yerel kayıt önbellek olarak kullanılır: her yazma iki
/// yere de gider, okuma bulut başarısız olursa yerelden döner. Böylece
/// bağlantı yokken bile ilerleme kaybolmaz.
class FirestoreCardStorage implements CardStorage {
  FirestoreCardStorage({
    required this.userId,
    FirebaseFirestore? firestore,
    this.local,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  /// Yerel önbellek; verilmezse yalnızca bulut kullanılır.
  final CardStorage? local;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(_usersCollection).doc(userId);

  @override
  Future<StoredCollection> load() async {
    try {
      final snapshot = await _doc.get();
      final data = snapshot.data();
      final field = data?[_collectionField];

      if (field is Map) {
        final map = field.cast<String, dynamic>();
        return (
          collected: {for (final id in _list(map['collected'])) id},
          stars: map['stars'] is int ? map['stars'] as int : 0,
        );
      }
      // Belge yok ya da alan boş: yeni kullanıcı. Yerelde bir şey varsa
      // (ör. bulut eklenmeden önce oynanmış) onu kullan ve buluta taşı.
      final fallback = await local?.load();
      if (fallback != null && fallback.collected.isNotEmpty) {
        await persist(fallback);
        return fallback;
      }
      return (collected: <String>{}, stars: 0);
    } catch (error) {
      debugPrint('Koleksiyon buluttan okunamadı ($error); yerele düşülüyor.');
      return await local?.load() ?? (collected: <String>{}, stars: 0);
    }
  }

  @override
  Future<void> persist(StoredCollection state) async {
    // Yerel önce yazılır: bulut yazması uzun sürse ya da başarısız olsa bile
    // ilerleme cihazda durur.
    await local?.persist(state);

    try {
      await _doc.set({
        _collectionField: {
          'collected': state.collected.toList(),
          'stars': state.stars,
        },
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Koleksiyon buluta yazılamadı: $error');
    }
  }
}

/// Oyuncu profilinin (istatistik, aksesuar, rozet) bulut kaydı.
class FirestoreProfileStorage implements ProfileStorage {
  FirestoreProfileStorage({
    required this.userId,
    FirebaseFirestore? firestore,
    this.local,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  /// Yerel önbellek; verilmezse yalnızca bulut kullanılır.
  final ProfileStorage? local;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(_usersCollection).doc(userId);

  @override
  Future<StoredProfile> load() async {
    try {
      final snapshot = await _doc.get();
      final field = snapshot.data()?[_profileField];

      if (field is Map) {
        return StoredProfile.fromJson(field.cast<String, dynamic>());
      }
      final fallback = await local?.load();
      if (fallback != null && fallback.totalStarsEarned > 0) {
        await persist(fallback);
        return fallback;
      }
      return const StoredProfile();
    } catch (error) {
      debugPrint('Profil buluttan okunamadı ($error); yerele düşülüyor.');
      return await local?.load() ?? const StoredProfile();
    }
  }

  @override
  Future<void> persist(StoredProfile profile) async {
    await local?.persist(profile);

    try {
      await _doc.set({
        _profileField: profile.toJson(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Profil buluta yazılamadı: $error');
    }
  }
}

List<String> _list(Object? value) =>
    value is List ? [for (final item in value) '$item'] : const [];
