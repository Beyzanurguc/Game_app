import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/card_collection.dart';
import 'package:game_app/cards/card_deck.dart';
import 'package:game_app/cards/card_storage.dart';

/// Bu dosyada `SharedPreferences.setMockInitialValues` bilinçli olarak
/// çağrılmaz: eklenti kayıtlı değilken (MissingPluginException) uygulamanın
/// çökmemesi gerektiğini doğrular.
void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  test('eklenti yoksa load boş durum döner, hata fırlatmaz', () async {
    final storage = SharedPreferencesCardStorage();

    final state = await storage.load();

    expect(state.collected, isEmpty);
    expect(state.stars, 0);
  });

  test('eklenti yoksa oyun bellekte çalışmaya devam eder', () async {
    final collection = await CardCollection.restore(
      storage: SharedPreferencesCardStorage(),
    );

    collection.save(cardDeck.first);
    collection.addStars(4);
    await collection.pending;

    expect(collection.isCollected(cardDeck.first.id), isTrue);
    expect(collection.stars, 4);
  });
}
