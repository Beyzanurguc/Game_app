import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cards/card_collection.dart';
import 'cards/card_repository.dart';
import 'cards/card_storage.dart';
import 'firebase/auth_service.dart';
import 'firebase/firestore_storage.dart';
import 'firebase/session_scope.dart';
import 'firebase_options.dart';
import 'games/yapboz/puzzle_catalog.dart';
import 'games/yapboz/puzzle_library.dart';
import 'home_screen.dart';
import 'profile/player_profile.dart';
import 'profile/profile_storage.dart';
import 'settings/app_settings.dart';
import 'settings/haptics.dart';
import 'settings/settings_storage.dart';
import 'settings/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/squishy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _lockPortraitOnPhones();
  await Haptics.detect();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BootstrapApp());
}

/// Telefonlarda ekranı dikeye sabitler.
///
/// Sudoku, Tetris ve Blok tahtaları dikey için tasarlandı; telefon yan
/// çevrilince sığmıyorlar. Tablet bunun dışında: ana sayfanın geniş düzeni
/// orada bilerek var ve tahtalara da yer kalıyor.
Future<void> _lockPortraitOnPhones() async {
  final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
  if (view == null) return;

  final size = view.physicalSize / view.devicePixelRatio;
  if (size.shortestSide >= 600) return;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

/// Açılış akışı: oturum aç, içeriği indir, sonra oyunu göster.
///
/// Bilgi kartları ve yapbozlar Firestore'da tutulduğu için ilk açılışta
/// internet gerekir. Bağlantı yoksa oyun boş açılmaz; ne olduğunu anlatan ve
/// yeniden denemeye izin veren bir ekran gösterilir.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({
    super.key,
    this.authService,
    this.cardRepository,
    this.puzzleRepository,
  });

  /// Testler için değiştirilebilir bağımlılıklar; verilmezse Firebase.
  final AuthService? authService;
  final CardRepository? cardRepository;
  final PuzzleRepository? puzzleRepository;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

/// Açılışın nerede olduğu.
enum _Phase { loading, ready, failed }

class _BootstrapAppState extends State<BootstrapApp> {
  /// Giriş ve çıkışın aynı oturumu görmesi için tek örnek tutulur.
  late final AuthService _auth = widget.authService ?? FirebaseAuthService();

  _Phase _phase = _Phase.loading;

  CardCollection? _collection;
  PlayerProfile? _profile;
  AppSettings? _settings;
  List<PuzzlePicture> _puzzles = const [];

  /// Kullanıcıya gösterilecek hata sebebi.
  String _failure = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _failure = '';
    });

    final cardRepository = widget.cardRepository ?? FirestoreCardRepository();
    final puzzleRepository =
        widget.puzzleRepository ?? FirestorePuzzleRepository();

    final userId = await _auth.signIn();
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _failure =
            'Oyuna bağlanılamadı. İnternet bağlantını kontrol edip yeniden '
            'dene.';
      });
      return;
    }

    // Kartlar ve yapbozlar birbirinden bağımsız; paralel indirilir.
    final results = await Future.wait([
      cardRepository.fetchCards(),
      puzzleRepository.fetchPuzzles(),
    ]);
    final deck = results[0] as List<dynamic>;
    final puzzles = results[1] as List<dynamic>;

    if (deck.isEmpty) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _failure =
            'Bilgi kartları yüklenemedi. Bağlantını kontrol edip yeniden '
            'dene.';
      });
      return;
    }

    // Bulut ana kayıt, yerel kayıt önbellek: bağlantı koparsa ilerleme
    // cihazda durmaya devam eder.
    final collection = await CardCollection.restore(
      deck: deck.cast(),
      storage: FirestoreCardStorage(
        userId: userId,
        local: SharedPreferencesCardStorage(),
      ),
    );
    final profile = await PlayerProfile.restore(
      storage: FirestoreProfileStorage(
        userId: userId,
        local: SharedPreferencesProfileStorage(),
      ),
    );
    // Ayarlar bilerek cihazda kalıyor: çocuğun adı kişisel veri, buluta
    // taşımak ayrı bir sorumluluk.
    final settings = await AppSettings.restore(
      storage: SharedPreferencesSettingsStorage(),
    );

    if (!mounted) return;
    setState(() {
      _collection = collection;
      _profile = profile;
      _settings = settings;
      _puzzles = puzzles.cast();
      _phase = _Phase.ready;
    });
  }

  /// Oturumu kapatır ve uygulamayı ilk açılıştaki hâline döndürür.
  ///
  /// Sıra önemli: önce yerel kayıt temizlenir, sonra oturum kapatılır.
  /// Tersi olsaydı [_load] araya girip yeni `uid` altına eski ilerlemeyi
  /// yazabilirdi. Ardından [_load] yeni bir anonim hesapla baştan çalışır;
  /// ayarlar sıfırlandığı için uygulama giriş sayfasına açılır.
  Future<void> _signOut() async {
    await clearLocalState();
    await _auth.signOut();
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.loading => const _BootstrapShell(child: _LoadingView()),
      _Phase.failed => _BootstrapShell(
        child: _FailureView(message: _failure, onRetry: _load),
      ),
      _Phase.ready => GameApp(
        collection: _collection!,
        profile: _profile,
        settings: _settings,
        puzzles: _puzzles,
        onSignOut: _signOut,
      ),
    };
  }
}

/// Açılış ekranlarını uygulama temasıyla saran kabuk.
class _BootstrapShell extends StatelessWidget {
  const _BootstrapShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foxium',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Center(child: child)),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Mascot(size: 140),
        SizedBox(height: AppSpacing.gutter),
        CircularProgressIndicator(color: AppColors.foxOrange),
        SizedBox(height: AppSpacing.base * 2),
        Text('Kartlar hazırlanıyor...', style: AppText.bodyLg),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(size: 140, mood: MascotMood.sad),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            'Bağlanamadım',
            style: AppText.headlineMd.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Squishy(
            key: const ValueKey('bootstrap_retry'),
            onTap: onRetry,
            color: AppColors.foxOrange,
            depthColor: AppColors.primary,
            radius: AppRadius.md,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            child: Text(
              'YENİDEN DENE',
              style: AppText.labelLg.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yüklenmiş durumla çalışan uygulama gövdesi.
///
/// Açılış akışından ayrı tutuldu: testler bu widget'ı doğrudan kurup
/// Firebase'e hiç dokunmadan ekranları deneyebiliyor.
class GameApp extends StatelessWidget {
  const GameApp({
    super.key,
    required this.collection,
    this.profile,
    this.settings,
    this.puzzles = const [],
    this.onSignOut,
  });

  final CardCollection collection;

  /// Verilmezse bellek içi boş profil kullanılır (testler ve önizleme).
  final PlayerProfile? profile;

  /// Verilmezse giriş sayfası gösterilir (ilk açılış davranışı).
  final AppSettings? settings;

  /// Yapboz ekranının kullanacağı resimler.
  final List<PuzzlePicture> puzzles;

  /// Verilmezse ayarlar sayfasında çıkış düğmesi gösterilmez; çıkış açılış
  /// akışını baştan çalıştırmayı gerektirdiği için yalnızca [BootstrapApp]
  /// bunu sağlayabilir.
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final app = CardCollectionScope(
      collection: collection,
      child: PlayerProfileScope(
        profile: profile ?? PlayerProfile(),
        child: AppSettingsScope(
          settings: settings ?? AppSettings(),
          child: PuzzleLibraryScope(
            pictures: puzzles,
            child: MaterialApp(
              title: 'Foxium',
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              home: const _RootScreen(),
            ),
          ),
        ),
      ),
    );

    final signOut = onSignOut;
    if (signOut == null) return app;
    return SessionScope(onSignOut: signOut, child: app);
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
