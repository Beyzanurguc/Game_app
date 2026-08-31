import 'package:flutter/material.dart';
import 'cards/card_collection.dart';
import 'cards/card_storage.dart';
import 'home_screen.dart';
import 'profile/player_profile.dart';
import 'profile/profile_storage.dart';
import 'settings/app_settings.dart';
import 'settings/settings_storage.dart';
import 'settings/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Kayıtlı kartlar, yıldızlar, oyuncu profili ve ayarlar açılışta okunur.
  final collection = await CardCollection.restore(
    storage: SharedPreferencesCardStorage(),
  );
  final profile = await PlayerProfile.restore(
    storage: SharedPreferencesProfileStorage(),
  );
  final settings = await AppSettings.restore(
    storage: SharedPreferencesSettingsStorage(),
  );

  runApp(GameApp(collection: collection, profile: profile, settings: settings));
}

class GameApp extends StatelessWidget {
  const GameApp({
    super.key,
    required this.collection,
    this.profile,
    this.settings,
  });

  final CardCollection collection;

  /// Verilmezse bellek içi boş profil kullanılır (testler ve önizleme).
  final PlayerProfile? profile;

  /// Verilmezse giriş sayfası gösterilir (ilk açılış davranışı).
  final AppSettings? settings;

  @override
  Widget build(BuildContext context) {
    return CardCollectionScope(
      collection: collection,
      child: PlayerProfileScope(
        profile: profile ?? PlayerProfile(),
        child: AppSettingsScope(
          settings: settings ?? AppSettings(),
          child: MaterialApp(
            title: 'Tilki Oyun',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: const _RootScreen(),
          ),
        ),
      ),
    );
  }
}

/// Açılışta hangi ekranın geleceğine karar verir.
///
/// Giriş sayfası tamamlanır tamamlanmaz ayarlar dinleyicileri uyardığı için
/// burası kendiliğinden ana sayfaya geçer.
class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope.of(context).onboarded
        ? const HomeScreen()
        : const WelcomeScreen();
  }
}
