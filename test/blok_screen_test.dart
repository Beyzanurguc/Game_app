import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/blok/blok_engine.dart';
import 'package:game_app/games/blok/blok_screen.dart';

import 'helpers.dart';

/// Tek hücrelik parça — hamleleri tek tek denetlemek için.
BlokPiece dot([BlokKind kind = BlokKind.fox]) =>
    BlokPiece.fromPattern(['X'], kind: kind);

/// Ekranı sabit parça dizisiyle açar (deterministik test için).
Future<void> pumpBlok(WidgetTester tester, {List<BlokPiece>? sequence}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapApp(BlokScreen(sequence: sequence ?? [dot()])));
  await tester.pump();
}

/// Puan göstergesindeki değeri okur.
///
/// Puan bir AnimatedSwitcher içinde; geçiş sırasında eski değer de ağaçta
/// kaldığı için en son eklenen okunur.
int readScore(WidgetTester tester) {
  final scores = tester
      .widgetList<Text>(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('blok_score_'),
        ),
      )
      .toList();
  return int.parse(scores.last.data!);
}

Finder filledCell(int row, int col) =>
    find.byKey(ValueKey('blok_filled_${row}_$col'));

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  testWidgets('oyun ekranı açılır ve tepsi doludur', (tester) async {
    await pumpBlok(tester);

    expect(readScore(tester), 0);
    expect(find.text('Sıra 0'), findsOneWidget);
    expect(find.text('Kombo 0'), findsOneWidget);
    expect(find.text('İPUCU 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('blok_tray_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('blok_tray_2')), findsOneWidget);

    // Tahta boş başlar.
    expect(filledCell(0, 0), findsNothing);

    // Oyun içinde alt gezinme çubuğu yok.
    for (final label in ['Oyunlar', 'Albüm', 'Rozetler', 'Ayarlar']) {
      expect(find.text(label), findsNothing);
    }
  });

  testWidgets('parçaya sonra hücreye dokunmak parçayı yerleştirir', (
    tester,
  ) async {
    await pumpBlok(tester);

    await tapKey(tester, 'blok_tray_0');
    await tapKey(tester, 'blok_cell_3_4');

    expect(filledCell(3, 4), findsOneWidget);
    expect(readScore(tester), 1);
  });

  testWidgets('parça seçilmeden hücreye dokunmak bir şey yapmaz', (
    tester,
  ) async {
    await pumpBlok(tester);

    await tapKey(tester, 'blok_cell_3_4');

    expect(filledCell(3, 4), findsNothing);
    expect(readScore(tester), 0);
  });

  testWidgets('parça tepsiden tahtaya sürüklenebilir', (tester) async {
    await pumpBlok(tester);

    final from = tester.getCenter(find.byKey(const ValueKey('blok_tray_0')));
    final to = tester.getCenter(find.byKey(const ValueKey('blok_cell_4_5')));

    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 250));

    // Parça parmağın bir hücre üstünde durur; bırakılan yer bir satır yukarısı.
    expect(filledCell(3, 5), findsOneWidget);
    expect(readScore(tester), 1);
  });

  testWidgets('tahta tamamen boşalınca özel kutlama gösterilir', (
    tester,
  ) async {
    await pumpBlok(tester);

    for (var col = 0; col < BlokGame.size; col++) {
      await tapKey(tester, 'blok_tray_${col % BlokGame.trayCount}');
      await tapKey(tester, 'blok_cell_0_$col');
    }

    expect(find.text('TAHTA TEMİZ!'), findsOneWidget);
    expect(
      readScore(tester),
      BlokGame.size + BlokGame.lineBase + BlokGame.clearBoardBonus,
    );
  });

  testWidgets('dolan satır temizlenir ve kutlama gösterilir', (tester) async {
    await pumpBlok(tester);

    // Uzaktaki tek blok tahtanın tamamen boşalmasını engeller; böylece
    // "tahta temiz" değil, normal sıra kutlaması beklenir.
    await tapKey(tester, 'blok_tray_0');
    await tapKey(tester, 'blok_cell_7_0');

    // 8 hücreyi tek tek koyarak üst satırı doldur.
    for (var col = 0; col < BlokGame.size; col++) {
      await tapKey(tester, 'blok_tray_${(col + 1) % BlokGame.trayCount}');
      await tapKey(tester, 'blok_cell_0_$col');
    }

    expect(find.text('SÜPER!'), findsOneWidget);
    expect(find.text('Sıra 1'), findsOneWidget);
    // Satır temizlendiği için hücreler yeniden boş.
    expect(filledCell(0, 0), findsNothing);
    expect(filledCell(7, 0), findsOneWidget);
    expect(readScore(tester), 1 + BlokGame.size + BlokGame.lineBase);
  });

  testWidgets('ipucu hakkı azalır ve biter', (tester) async {
    await pumpBlok(tester);

    await tapKey(tester, 'blok_hint');
    expect(find.text('İPUCU 2'), findsOneWidget);

    await tapKey(tester, 'blok_hint');
    await tapKey(tester, 'blok_hint');
    expect(find.text('İPUCU 0'), findsOneWidget);

    // Hak bitince düğme çalışmaz.
    await tapKey(tester, 'blok_hint');
    expect(find.text('İPUCU 0'), findsOneWidget);
  });

  testWidgets('duraklatma penceresi açılır ve oyuna dönülür', (tester) async {
    await pumpBlok(tester);

    await tapKey(tester, 'blok_pause');
    expect(find.text('Mola verdik'), findsOneWidget);

    await tapKey(tester, 'pause_resume');
    expect(find.text('Mola verdik'), findsNothing);
    expect(find.text('İPUCU 3'), findsOneWidget);
  });

  testWidgets('oyun bitince ödül kartı ekranı açılır', (tester) async {
    await pumpBlok(tester);

    await tapKey(tester, 'blok_tray_0');
    await tapKey(tester, 'blok_cell_2_2');

    // Hata ayıklama düğmesi oyunu bitirir.
    await tapKey(tester, 'blok_debug_end');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reward_primary')), findsOneWidget);
  });
}
