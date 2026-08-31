import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/yapboz/puzzle_catalog.dart';
import 'package:game_app/games/yapboz/yapboz_board.dart';
import 'package:game_app/games/yapboz/yapboz_engine.dart';
import 'package:game_app/games/yapboz/yapboz_screen.dart';

import 'helpers.dart';

Future<void> pumpYapboz(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapApp(const YapbozScreen()));
  await tester.pump();
}

/// Kurulum listesi uzun ve tembel yüklenir; alttaki kartlar ancak
/// kaydırılınca inşa edilir.
Future<void> scrollToSetupItem(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    // İçerideki GridView'lar da Scrollable; dıştaki listeninki ilk sırada.
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('yapboz_setup_list')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump();
}

void main() {
  group('puzzleCatalog', () {
    test('her resmin dosyası diskte var', () {
      final missing = puzzlePictures
          .where((p) => !File(p.asset).existsSync())
          .map((p) => p.asset)
          .toList();
      expect(missing, isEmpty, reason: 'eksik yapboz görseli');
    });

    test('asset yolları pubspec içindeki klasörün altında', () {
      for (final picture in puzzlePictures) {
        expect(
          picture.asset,
          startsWith('assets/images/puzzles/'),
          reason: picture.id,
        );
      }
    });

    testWidgets('her resim kare ve 1200 piksel', (tester) async {
      // Yapboz ızgarası kare; kare olmayan bir görsel tahtada sessizce
      // kırpılır. tools/prepare_puzzle_images.py bunu baştan halleder, bu test
      // de betiği çalıştırmayı unutmayı yakalar.
      // Görsel çözme gerçek async gerektirir; testWidgets'in sahte saati
      // altında asılı kalır, bu yüzden runAsync şart.
      final sizes = await tester.runAsync(() async {
        final result = <String, (int, int)>{};
        for (final picture in puzzlePictures) {
          final bytes = await File(picture.asset).readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          result[picture.id] = (frame.image.width, frame.image.height);
          frame.image.dispose();
          codec.dispose();
        }
        return result;
      });

      for (final entry in sizes!.entries) {
        final (width, height) = entry.value;
        expect(
          width,
          height,
          reason: '${entry.key} kare değil (${width}x$height)',
        );
        expect(width, 1200, reason: entry.key);
      }
    });

    test('kimlikler ve başlıklar benzersiz', () {
      expect(
        puzzlePictures.map((p) => p.id).toSet(),
        hasLength(puzzlePictures.length),
      );
      expect(
        puzzlePictures.map((p) => p.title).toSet(),
        hasLength(puzzlePictures.length),
      );
    });
  });

  group('YapbozScreen', () {
    testWidgets('önce resim ve zorluk seçimi gösterilir', (tester) async {
      await pumpYapboz(tester);

      expect(find.text('Hangi resmi yapalım?'), findsOneWidget);
      expect(find.text(puzzlePictures.first.title), findsOneWidget);
      // Başla düğmesi sabit alt çubukta; kaydırmadan görünür.
      expect(find.text('BAŞLA'), findsOneWidget);

      await scrollToSetupItem(tester, find.text('Zorluk'));
      expect(find.text('Zorluk'), findsOneWidget);
      for (final difficulty in YapbozDifficulty.values) {
        await scrollToSetupItem(tester, find.text(difficulty.label));
        expect(find.text(difficulty.label), findsOneWidget);
      }
    });

    testWidgets('BAŞLA tahtayı seçilen zorlukta açar', (tester) async {
      await pumpYapboz(tester);

      await scrollToSetupItem(tester, find.text('Kolay'));
      await tester.tap(find.text('Kolay'));
      await tester.pump();
      await tester.tap(find.text('BAŞLA'));
      await tester.pump();

      // Başlık seçilen resmin adı olur.
      expect(find.text(puzzlePictures.first.title), findsOneWidget);
      expect(find.text('Yerine oturan: 0 / 9'), findsOneWidget);
      expect(find.text('Parçalar'), findsOneWidget);
      expect(find.byKey(const ValueKey('yapboz_hint')), findsOneWidget);
    });

    testWidgets('zor seviye 25 parçalı tahta açar', (tester) async {
      await pumpYapboz(tester);

      await scrollToSetupItem(tester, find.text('Zor'));
      await tester.tap(find.text('Zor'));
      await tester.pump();
      await tester.tap(find.text('BAŞLA'));
      await tester.pump();

      expect(find.text('Yerine oturan: 0 / 25'), findsOneWidget);
    });

    testWidgets('ipucu bir parçayı yerine oturtur ve hak azalır', (
      tester,
    ) async {
      await pumpYapboz(tester);
      await tester.tap(find.text('BAŞLA'));
      await tester.pump();

      expect(find.text('İpucu (3)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('yapboz_hint')));
      await tester.pump();

      expect(find.text('İpucu (2)'), findsOneWidget);
      expect(find.text('Yerine oturan: 1 / 9'), findsOneWidget);
    });

    testWidgets('resmi göster düğmesi önizlemeyi açıp kapatır', (tester) async {
      await pumpYapboz(tester);
      await tester.tap(find.text('BAŞLA'));
      await tester.pump();

      expect(find.text('Resmi göster'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('yapboz_preview')));
      await tester.pump();
      expect(find.text('Resmi gizle'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('yapboz_preview')));
      await tester.pump();
      expect(find.text('Resmi göster'), findsOneWidget);
    });

    testWidgets('parça tepsiden tahtaya sürüklenip yerine oturur', (
      tester,
    ) async {
      await pumpYapboz(tester);
      await tester.tap(find.text('BAŞLA'));
      await tester.pump();

      // Tepsi yatay ve tembel yüklenen bir liste; kaç parçanın inşa edildiği
      // görünüm genişliğine bağlı olduğu için sayıya değil yuva içeriğine
      // bakıyoruz.
      final trayPieces = find.descendant(
        of: find.byKey(const ValueKey('yapboz_tray')),
        matching: find.byType(PuzzlePieceImage),
      );
      expect(trayPieces, findsWidgets);

      final slotZero = find.descendant(
        of: find.byKey(const ValueKey('yapboz_slot_0')),
        matching: find.byType(PuzzlePieceImage),
      );
      expect(slotZero, findsNothing, reason: 'yuva başta boş');

      // Tepsideki ilk parçayı sol üst yuvaya sürükle.
      final start = tester.getCenter(trayPieces.first);
      final target = tester.getCenter(
        find.byKey(const ValueKey('yapboz_slot_0')),
      );

      final before = tester.widgetList(find.byType(PuzzlePieceImage)).length;

      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pump();

      // Sürüklerken parça parmağın altında da çizilir.
      expect(
        tester.widgetList(find.byType(PuzzlePieceImage)).length,
        before + 1,
        reason: 'yüzen parça',
      );

      await gesture.up();
      await tester.pump();

      // Parça tahtaya kondu.
      expect(slotZero, findsOneWidget);
    });

    testWidgets('tahtadaki parça tepsiye geri sürüklenebilir', (tester) async {
      await pumpYapboz(tester);
      await tester.tap(find.text('BAŞLA'));
      await tester.pump();

      // Önce ipucuyla bir parçayı yerine oturt.
      await tester.tap(find.byKey(const ValueKey('yapboz_hint')));
      await tester.pump();
      expect(find.text('Yerine oturan: 1 / 9'), findsOneWidget);

      // Dolu yuvayı bul ve tahtanın dışına sürükle.
      final placed = find
          .descendant(
            of: find.byType(AspectRatio).first,
            matching: find.byType(PuzzlePieceImage),
          )
          .first;
      final start = tester.getCenter(placed);
      final outside = tester.getCenter(
        find.byKey(const ValueKey('yapboz_tray')),
      );

      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveTo(outside);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(find.text('Yerine oturan: 0 / 9'), findsOneWidget);
    });
  });
}
