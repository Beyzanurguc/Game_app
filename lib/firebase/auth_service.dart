import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Oturum yönetimi.
///
/// Uygulama anonim giriş kullanır: çocuktan hiçbir kimlik bilgisi istenmez,
/// giriş ekranı yoktur. Firebase her kuruluma bir `uid` verir ve ilerleme
/// buluta o kimlik altında yazılır.
///
/// Bilinen sınır: anonim hesap cihaza/kuruluma bağlıdır. Uygulama silinip
/// yeniden kurulursa yeni bir uid alınır ve buluttaki eski ilerlemeye
/// ulaşılamaz. İlerlemenin cihazlar arası taşınması istenirse anonim hesabın
/// bir ebeveyn hesabına bağlanması gerekir.
abstract interface class AuthService {
  /// Oturum açar ve kullanıcı kimliğini döner.
  ///
  /// Bağlantı yoksa ya da Firebase reddederse `null` döner; çağıran taraf
  /// buna göre çevrimdışı davranır.
  Future<String?> signIn();

  /// Şu anki kullanıcı kimliği; oturum yoksa `null`.
  String? get currentUserId;
}

/// Firebase Authentication üzerinden anonim oturum.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<String?> signIn() async {
    // Firebase oturumu diske yazar; ikinci açılışta zaten oturum vardır.
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;

    try {
      final credential = await _auth.signInAnonymously();
      return credential.user?.uid;
    } on FirebaseAuthException catch (error) {
      // En sık sebep: konsolda "Anonymous" sağlayıcısı açılmamış olması.
      debugPrint(
        'Anonim giriş başarısız (${error.code}). '
        'Firebase konsolunda Authentication > Sign-in method altında '
        'Anonymous açık mı?',
      );
      return null;
    } catch (error) {
      debugPrint('Anonim giriş başarısız: $error');
      return null;
    }
  }
}

/// Testler için sabit kimlik döndüren oturum.
class FakeAuthService implements AuthService {
  FakeAuthService({this.userId = 'test-user'});

  /// `null` verilirse giriş başarısız sayılır.
  final String? userId;

  @override
  String? get currentUserId => userId;

  @override
  Future<String?> signIn() async => userId;
}
