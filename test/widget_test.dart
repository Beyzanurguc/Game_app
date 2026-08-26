import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_app/main.dart';

import 'helpers.dart';

/// Ekranı telefon boyutuna sabitler (varsayılan test yüzeyi 800x600'dür).
Future<void> _pumpPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GameApp(collection: testCollection(), settings: testSettings()),
  );
}

/// Ana sayfayı kaydırır.
///
/// Rozet vitrini yatay bir liste olduğu için sayfada birden çok kaydırılabilir
/// alan var; dıştaki ana liste açıkça seçilir.
Future<void> _scrollHomeTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  testWidgets('Telefon düzeni: selamlama, albüm ve oyunlar görünür', (
    tester,
  ) async {
    await _pumpPhone(tester);

    expect(find.text('Merhaba, Beyza!'), findsOneWidget);
    // Üstte günlük oyun kartı, altında bilgi albümü kartı.
    expect(find.text('Bugünün oyunları'), findsOneWidget);
    expect(find.textContaining('oyun oynadın'), findsOneWidget);
    expect(find.text('Bilgi albümüm'), findsOneWidget);
    expect(find.textContaining('kart toplandı'), findsOneWidget);
    // Atölye kartı kaldırıldı; kısayol avatarda.
    expect(find.text('Tilki Atölyesi'), findsNothing);

    expect(find.text('Tetris'), findsOneWidget);

    // Alttaki kartlar listeyi kaydırınca görünür olmalı.
    for (final game in ['Sudoku', 'Blok Patlat', 'Yakında']) {
      await _scrollHomeTo(tester, find.text(game));
      expect(find.text(game), findsOneWidget);
    }
  });

  testWidgets('Geniş ekran düzeni taşma olmadan çizilir', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GameApp(collection: testCollection(), settings: testSettings()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tetris'), findsOneWidget);
  });

  testWidgets('Ana sayfadan Blok Patlat açılır', (tester) async {
    await _pumpPhone(tester);

    // Kart listenin altında; alt gezinme çubuğunun üstüne gelecek kadar kaydır.
    await _scrollHomeTo(tester, find.text('Blok Patlat'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blok Patlat'));
    await tester.pump();
    // Sayfa geçiş animasyonunun bitmesini bekle (oyun zamanlayıcısı
    // sürdüğü için pumpAndSettle kullanılmaz).
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('İPUCU 3'), findsOneWidget);
    expect(find.text('Sıra 0'), findsOneWidget);
    expect(find.text('Rozetler'), findsNothing); // alt bar gizli
  });

  testWidgets('Ana sayfadan Tetris açılır', (tester) async {
    await _pumpPhone(tester);

    await tester.tap(find.text('Tetris'));
    await tester.pump();
    // Sayfa geçiş animasyonunun bitmesini bekle (oyun zamanlayıcısı
    // sürdüğü için pumpAndSettle kullanılmaz).
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('SIRADAKİ'), findsOneWidget);
    expect(find.text('AŞAĞI'), findsOneWidget);
    expect(find.text('Rozetler'), findsNothing); // alt bar gizli
  });

  testWidgets('Alt gezinmede oyunlar sekmesi seçili durur', (tester) async {
    await _pumpPhone(tester);

    // Diğer sekmeler üste sayfa açtığı için seçili sekme hep bu sayfadır.
    final pill = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Oyunlar'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect((pill.decoration! as BoxDecoration).color, const Color(0xFFF47D31));
  });

  testWidgets('Alt gezinmeden ayarlar sayfası açılıp kapanır', (tester) async {
    await _pumpPhone(tester);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();

    expect(find.text('İsim'), findsOneWidget);
    expect(find.text('Günlük oyun hakkı'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings_back')));
    await tester.pumpAndSettle();

    expect(find.text('İsim'), findsNothing);
    expect(find.text('Bugünün oyunları'), findsOneWidget);
  });

  testWidgets('Alt gezinmeden rozet sayfası açılır', (tester) async {
    await _pumpPhone(tester);

    await tester.tap(find.text('Rozetler'));
    await tester.pumpAndSettle();

    expect(find.text('Rozetlerim'), findsOneWidget);
    expect(find.text('Kazanılan rozet'), findsOneWidget);
  });

  testWidgets('Avatardan tilki atölyesi açılır', (tester) async {
    await _pumpPhone(tester);

    // Atölye kartı kaldırıldı; kısayol selamlamadaki avatar.
    await tester.tap(find.byKey(const ValueKey('home_avatar')));
    await tester.pumpAndSettle();

    expect(find.text('Tilki Atölyesi'), findsOneWidget);
    expect(find.text('Yün Bere'), findsOneWidget);
  });
}
