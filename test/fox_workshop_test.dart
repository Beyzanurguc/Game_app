import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/card_collection.dart';
import 'package:game_app/profile/fox_avatar.dart';
import 'package:game_app/profile/fox_items.dart';
import 'package:game_app/profile/fox_workshop_screen.dart';
import 'package:game_app/profile/player_profile.dart';

import 'helpers.dart';

FoxItem itemOf(String id) => foxItems.firstWhere((item) => item.id == id);

/// Atölyeyi belirli bir yıldız bakiyesiyle açar.
Future<({CardCollection wallet, PlayerProfile profile})> pumpWorkshop(
  WidgetTester tester, {
  int stars = 200,
  PlayerProfile? profile,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final wallet = testCollection(stars: stars);
  final player = profile ?? PlayerProfile();

  await tester.pumpWidget(
    wrapApp(const FoxWorkshopScreen(), collection: wallet, profile: player),
  );
  await tester.pumpAndSettle();

  return (wallet: wallet, profile: player);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

/// Kutu listenin altındaysa önce görünür alana kaydırır.
Future<void> tapItem(WidgetTester tester, String id) async {
  final finder = find.byKey(ValueKey('shop_item_$id'));
  await tester.scrollUntilVisible(
    finder,
    120,
    // Sayfada yatay bölge çubuğu da var; kaydırılacak olan kutu ızgarası.
    scrollable: find.descendant(
      of: find.byType(GridView),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('atölye açılır, şapkalar ve bakiye görünür', (tester) async {
    await pumpWorkshop(tester, stars: 60);

    expect(find.text('Tilki Atölyesi'), findsOneWidget);
    expect(find.byKey(const ValueKey('star_balance_60')), findsOneWidget);
    expect(find.text('Yün Bere'), findsOneWidget);

    // Başka bölgenin aksesuarları listede değil.
    expect(find.text('Papyon'), findsNothing);
    expect(find.text('Tilkiyi süslemeye hazır!'), findsOneWidget);
  });

  testWidgets('bölge çipi listeyi değiştirir', (tester) async {
    await pumpWorkshop(tester);

    await tapKey(tester, 'shop_slot_neck');

    expect(find.text('Papyon'), findsOneWidget);
    expect(find.text('Yün Bere'), findsNothing);
  });

  testWidgets('aksesuar satın alınca yıldız düşer ve takılır', (tester) async {
    final state = await pumpWorkshop(tester, stars: 60);

    await tapItem(tester, 'beanie');
    expect(find.text('ALALIM!'), findsOneWidget);
    expect(find.textContaining('45 yıldızın kalır'), findsOneWidget);

    await tapKey(tester, 'buy_confirm');

    expect(state.wallet.stars, 45);
    expect(state.profile.owns('beanie'), isTrue);
    expect(state.profile.isEquipped(itemOf('beanie')), isTrue);
    expect(find.text('TAKILI'), findsOneWidget);
    expect(find.byKey(const ValueKey('star_balance_45')), findsOneWidget);
  });

  testWidgets('satın almadan vazgeçilince yıldız harcanmaz', (tester) async {
    final state = await pumpWorkshop(tester, stars: 60);

    await tapItem(tester, 'beanie');
    await tapKey(tester, 'buy_cancel');

    expect(state.wallet.stars, 60);
    expect(state.profile.ownedCount, 0);
  });

  testWidgets('yıldız yetmezse uyarı verilir', (tester) async {
    final state = await pumpWorkshop(tester, stars: 10);

    await tapItem(tester, 'crown');

    expect(find.text('ALALIM!'), findsNothing);
    expect(find.text('110 yıldız daha lazım!'), findsOneWidget);
    expect(state.wallet.stars, 10);
  });

  testWidgets('sahip olunan aksesuar takılıp çıkarılabilir', (tester) async {
    final profile = PlayerProfile()..unlock(itemOf('beanie'));
    final state = await pumpWorkshop(tester, profile: profile);

    expect(find.text('TAKILI'), findsOneWidget);

    // Takılıyken dokunmak çıkarır.
    await tapItem(tester, 'beanie');
    expect(state.profile.equippedItems, isEmpty);
    expect(find.text('TAK'), findsOneWidget);

    // Yeniden dokunmak takar; yıldız harcanmaz.
    await tapItem(tester, 'beanie');
    expect(state.profile.isEquipped(itemOf('beanie')), isTrue);
    expect(state.wallet.stars, 200);
  });

  testWidgets('"Yok" kutusu bölgeyi boşaltır', (tester) async {
    final profile = PlayerProfile()..unlock(itemOf('top_hat'));
    final state = await pumpWorkshop(tester, profile: profile);

    // Ad hem kutuda hem de sahnedeki "takılı" çipinde görünür.
    expect(find.text('Silindir Şapka'), findsNWidgets(2));

    await tapKey(tester, 'shop_remove');

    expect(state.profile.equippedIn(FoxSlot.hat), isNull);
    expect(find.text('Silindir Şapka'), findsOneWidget);
    expect(find.text('Tilkiyi süslemeye hazır!'), findsOneWidget);
  });

  testWidgets('takılı aksesuarlar avatarda çizilir', (tester) async {
    final profile = PlayerProfile()
      ..unlock(itemOf('crown'))
      ..unlock(itemOf('sunglasses'));
    await pumpWorkshop(tester, profile: profile);

    // Sahnedeki büyük avatar iki aksesuarı da taşır.
    final stage = tester.widgetList<FoxAvatar>(find.byType(FoxAvatar)).first;
    expect(stage.items.map((item) => item.id), ['crown', 'sunglasses']);
  });
}
