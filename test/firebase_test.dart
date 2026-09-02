import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/card_repository.dart';
import 'package:game_app/cards/card_storage.dart';
import 'package:game_app/cards/info_card.dart';
import 'package:game_app/firebase/firestore_storage.dart';
import 'package:game_app/games/yapboz/puzzle_catalog.dart';
import 'package:flutter/material.dart';
import 'package:game_app/profile/profile_storage.dart';

/// Firestore'a örnek bir kart belgesi yazar.
Future<void> seedCard(
  FakeFirebaseFirestore firestore,
  String id, {
  String title = 'Başlık',
  String category = 'hayvanlar',
  int order = 0,
  Map<String, dynamic>? quiz,
}) {
  return firestore.collection('cards').doc(id).set({
    'title': title,
    'question': 'Soru?',
    'answer': 'Cevap',
    'facts': ['bilgi'],
    'category': category,
    'emoji': '🦊',
    'order': order,
    'quiz': ?quiz,
  });
}

const _quiz = {
  'prompt': 'Soru?',
  'correctAnswer': 'Doğru',
  'distractors': ['Yanlış a', 'Yanlış b', 'Yanlış c'],
};

void main() {
  group('FirestoreCardRepository', () {
    test('kartları order sırasına göre getirir', () async {
      final firestore = FakeFirebaseFirestore();
      await seedCard(firestore, 'c', title: 'Üçüncü', order: 2);
      await seedCard(firestore, 'a', title: 'Birinci', order: 0);
      await seedCard(firestore, 'b', title: 'İkinci', order: 1);

      final cards = await FirestoreCardRepository(
        firestore: firestore,
      ).fetchCards();

      expect(cards.map((c) => c.id), ['a', 'b', 'c']);
      expect(cards.first.title, 'Birinci');
    });

    test('order eşitse başlığa göre sıralar', () async {
      final firestore = FakeFirebaseFirestore();
      await seedCard(firestore, 'z', title: 'Zebra');
      await seedCard(firestore, 'a', title: 'Ayı');

      final cards = await FirestoreCardRepository(
        firestore: firestore,
      ).fetchCards();

      expect(cards.map((c) => c.title), ['Ayı', 'Zebra']);
    });

    test('quiz alanı karta okunur', () async {
      final firestore = FakeFirebaseFirestore();
      await seedCard(firestore, 'a', quiz: _quiz);

      final cards = await FirestoreCardRepository(
        firestore: firestore,
      ).fetchCards();

      expect(cards.single.quiz, isNotNull);
      expect(cards.single.quiz!.isUsable, isTrue);
      expect(cards.single.quiz!.correctAnswer, 'Doğru');
    });

    test('başlıksız kart listeye alınmaz', () async {
      final firestore = FakeFirebaseFirestore();
      await seedCard(firestore, 'iyi', title: 'İyi kart');
      await firestore.collection('cards').doc('bos').set({'order': 1});

      final cards = await FirestoreCardRepository(
        firestore: firestore,
      ).fetchCards();

      expect(cards.map((c) => c.id), ['iyi']);
    });

    test('tanınmayan kategori kartı düşürmez', () async {
      final firestore = FakeFirebaseFirestore();
      await seedCard(firestore, 'a', category: 'olmayan_kategori');

      final cards = await FirestoreCardRepository(
        firestore: firestore,
      ).fetchCards();

      expect(cards, hasLength(1));
      expect(cards.single.category, CardCategory.bilim);
    });

    test('koleksiyon boşsa boş liste döner', () async {
      final cards = await FirestoreCardRepository(
        firestore: FakeFirebaseFirestore(),
      ).fetchCards();

      expect(cards, isEmpty);
    });
  });

  group('FirestoreCardStorage', () {
    test('yazdığını geri okur', () async {
      final firestore = FakeFirebaseFirestore();
      final storage = FirestoreCardStorage(userId: 'u1', firestore: firestore);

      await storage.persist((collected: {'a', 'b'}, stars: 30));
      final state = await storage.load();

      expect(state.collected, {'a', 'b'});
      expect(state.stars, 30);
    });

    test('yeni kullanıcıda boş durum döner', () async {
      final state = await FirestoreCardStorage(
        userId: 'yeni',
        firestore: FakeFirebaseFirestore(),
      ).load();

      expect(state.collected, isEmpty);
      expect(state.stars, 0);
    });

    test('yerel önbelleğe de yazar', () async {
      final local = MemoryCardStorage();
      final storage = FirestoreCardStorage(
        userId: 'u1',
        firestore: FakeFirebaseFirestore(),
        local: local,
      );

      await storage.persist((collected: {'a'}, stars: 5));

      expect((await local.load()).collected, {'a'});
      expect(local.writes, 1);
    });

    test('bulutta kayıt yoksa yereldeki ilerleme buluta taşınır', () async {
      // Bulut eklenmeden önce oynamış bir kullanıcı ilerlemesini kaybetmemeli.
      final firestore = FakeFirebaseFirestore();
      final local = MemoryCardStorage(collected: {'eski'}, stars: 12);
      final storage = FirestoreCardStorage(
        userId: 'u1',
        firestore: firestore,
        local: local,
      );

      final state = await storage.load();
      expect(state.collected, {'eski'});
      expect(state.stars, 12);

      // Taşınmış olmalı: yerel silinse bile bulutta durur.
      final cloudOnly = FirestoreCardStorage(
        userId: 'u1',
        firestore: firestore,
      );
      expect((await cloudOnly.load()).collected, {'eski'});
    });
  });

  group('FirestoreProfileStorage', () {
    test('yazdığını geri okur', () async {
      final firestore = FakeFirebaseFirestore();
      final storage = FirestoreProfileStorage(
        userId: 'u1',
        firestore: firestore,
      );

      await storage.persist(
        const StoredProfile(
          totalStarsEarned: 42,
          owned: {'sapka'},
          seenBadges: {'first_game'},
        ),
      );
      final profile = await storage.load();

      expect(profile.totalStarsEarned, 42);
      expect(profile.owned, {'sapka'});
      expect(profile.seenBadges, {'first_game'});
    });

    test('koleksiyon ve profil birbirini ezmez', () async {
      // İkisi de users/{uid} belgesine yazıyor; ayrı alanlarda durmalılar.
      final firestore = FakeFirebaseFirestore();
      final cards = FirestoreCardStorage(userId: 'u1', firestore: firestore);
      final profiles = FirestoreProfileStorage(
        userId: 'u1',
        firestore: firestore,
      );

      await cards.persist((collected: {'a'}, stars: 7));
      await profiles.persist(const StoredProfile(totalStarsEarned: 99));
      await cards.persist((collected: {'a', 'b'}, stars: 9));

      expect((await profiles.load()).totalStarsEarned, 99);
      expect((await cards.load()).collected, {'a', 'b'});
      expect((await cards.load()).stars, 9);
    });

    test('yeni kullanıcıda boş profil döner', () async {
      final profile = await FirestoreProfileStorage(
        userId: 'yeni',
        firestore: FakeFirebaseFirestore(),
      ).load();

      expect(profile.totalStarsEarned, 0);
      expect(profile.records, isEmpty);
    });
  });

  group('FirestorePuzzleRepository', () {
    // Storage ücretli plan istediği için görsel yapboz belgesinin içinde
    // bytes alanı olarak duruyor.
    final image = Uint8List.fromList(List.generate(64, (i) => i));

    Future<void> seedPuzzle(
      FakeFirebaseFirestore firestore,
      String id, {
      String title = 'Yapboz',
      int order = 0,
      Object? imageField = 'yerine-blob',
      String icon = 'pets',
    }) {
      return firestore.collection('puzzles').doc(id).set({
        'title': title,
        'accent': 0xFFF47D31,
        'icon': icon,
        'order': order,
        'image': imageField == 'yerine-blob' ? Blob(image) : imageField,
      });
    }

    test('görseli belgeden bayt olarak okur', () async {
      final firestore = FakeFirebaseFirestore();
      await seedPuzzle(firestore, 'kedi', title: 'Kedi');

      final puzzles = await FirestorePuzzleRepository(
        firestore: firestore,
      ).fetchPuzzles();

      expect(puzzles, hasLength(1));
      expect(puzzles.single.title, 'Kedi');
      expect(puzzles.single.imageBytes, image);
      expect(puzzles.single.accent.toARGB32(), 0xFFF47D31);
    });

    test('order sırasına göre sıralar', () async {
      final firestore = FakeFirebaseFirestore();
      await seedPuzzle(firestore, 'c', order: 2);
      await seedPuzzle(firestore, 'a', order: 0);
      await seedPuzzle(firestore, 'b', order: 1);

      final puzzles = await FirestorePuzzleRepository(
        firestore: firestore,
      ).fetchPuzzles();

      expect(puzzles.map((p) => p.id), ['a', 'b', 'c']);
    });

    test('görseli olmayan yapboz listeye alınmaz', () async {
      // Seçilebilir ama açılmayan yapboz, listede hiç olmamasından kötü.
      final firestore = FakeFirebaseFirestore();
      await seedPuzzle(firestore, 'iyi', title: 'İyi');
      await seedPuzzle(firestore, 'gorselsiz', imageField: null);
      await seedPuzzle(firestore, 'bos', imageField: Blob(Uint8List(0)));

      final puzzles = await FirestorePuzzleRepository(
        firestore: firestore,
      ).fetchPuzzles();

      expect(puzzles.map((p) => p.id), ['iyi']);
    });

    test('başlıksız yapboz listeye alınmaz', () async {
      final firestore = FakeFirebaseFirestore();
      await seedPuzzle(firestore, 'bos', title: '');

      final puzzles = await FirestorePuzzleRepository(
        firestore: firestore,
      ).fetchPuzzles();

      expect(puzzles, isEmpty);
    });

    test('tanınmayan simge anahtarı yapbozu düşürmez', () async {
      final firestore = FakeFirebaseFirestore();
      await seedPuzzle(firestore, 'a', icon: 'olmayan_simge');

      final puzzles = await FirestorePuzzleRepository(
        firestore: firestore,
      ).fetchPuzzles();

      expect(puzzles, hasLength(1));
      expect(puzzles.single.icon, Icons.extension_rounded);
    });
  });
}
