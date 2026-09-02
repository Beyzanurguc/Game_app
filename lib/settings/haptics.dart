import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vibration/vibration.dart';

import 'app_settings.dart';

/// Oyunlarda kullanılan titreşim türleri.
enum Buzz {
  /// Küçük bir seçim: hücreye dokunmak, parça almak.
  selection,

  /// Hafif onay.
  light,

  /// Bir şeyin yerine oturması, doğru cevap.
  medium,

  /// Oyunun bitmesi, hata, büyük an.
  heavy,
}

/// Bir türün süresi (ms) ve gücü (0-255).
typedef _BuzzProfile = ({int duration, int amplitude});

/// Süreler bilerek kısa: bunlar oyun içi geri bildirim, bildirim değil.
const Map<Buzz, _BuzzProfile> _profiles = {
  Buzz.selection: (duration: 12, amplitude: 70),
  Buzz.light: (duration: 18, amplitude: 110),
  Buzz.medium: (duration: 28, amplitude: 170),
  Buzz.heavy: (duration: 50, amplitude: 255),
};

/// Titreşimin nasıl üretileceğini belirler.
///
/// Flutter'ın `HapticFeedback`'i Android'de `View.performHapticFeedback`
/// çağırır; birçok cihaz gönderdiği sabitleri (özellikle `CLOCK_TICK`)
/// yok saydığı için hiçbir şey hissedilmiyor. Bu yüzden Android'de titreşim
/// motoruna doğrudan gidiliyor.
///
/// iOS'ta durum tersi: `HapticFeedback` Taptic Engine'i doğru kullanır, ham
/// titreşim ondan kaba kalır. Orada Flutter'ınki bırakıldı.
abstract final class Haptics {
  static bool _useVibrator = false;
  static bool _hasAmplitude = false;

  /// Titreşim motoruna doğrudan gidiliyor mu?
  static bool get useVibrator => _useVibrator;

  /// Cihaz titreşim gücünü ayarlayabiliyor mu?
  static bool get hasAmplitude => _hasAmplitude;

  /// Cihazın yeteneğini ölçer; açılışta bir kez çağrılır.
  ///
  /// [buzz] 26 yerden çağrılıyor ve senkron olmak zorunda, o yüzden sorgu
  /// burada bir kez yapılıp saklanıyor.
  static Future<void> detect() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      _useVibrator = await Vibration.hasVibrator();
      _hasAmplitude = _useVibrator && await Vibration.hasAmplitudeControl();
    } catch (error) {
      // Yetenek okunamadıysa Flutter'ın kendi yöntemine düşülür; titreşim
      // için açılışı riske atmaya değmez.
      debugPrint('Titreşim yeteneği okunamadı ($error).');
      _useVibrator = false;
      _hasAmplitude = false;
    }
  }

  /// Testler ölçüm yapmadan yolu seçebilsin diye.
  @visibleForTesting
  static void debugSetSupport({
    required bool useVibrator,
    bool hasAmplitude = false,
  }) {
    _useVibrator = useVibrator;
    _hasAmplitude = hasAmplitude;
  }
}

/// Ayarlardaki titreşim anahtarına uyarak titreştirir.
///
/// Tüm oyunlar `HapticFeedback` yerine bunu çağırır; anahtar tek yerden
/// dinlendiği için ekranların ayarı kendilerinin okuması gerekmez.
///
/// [context] ağaçtan çıkmışsa sessizce atlanır: titreşim, gecikmeli bir
/// zamanlayıcı yüzünden hata verdirmeye değmez.
void buzz(BuildContext context, Buzz kind) {
  if (!context.mounted) return;
  if (!AppSettingsScope.of(context).hapticsEnabled) return;

  if (!Haptics.useVibrator) {
    _flutterHaptic(kind);
    return;
  }

  final profile = _profiles[kind]!;
  // Beklenmiyor: titreşim oyunu bekletmemeli.
  unawaited(
    Vibration.vibrate(
      duration: profile.duration,
      amplitude: Haptics.hasAmplitude ? profile.amplitude : -1,
    ).catchError((Object error) {
      debugPrint('Titreşim başarısız: $error');
    }),
  );
}

/// Flutter'ın kendi geri bildirimi — iOS ve titreşim motoru olmayan cihazlar.
void _flutterHaptic(Buzz kind) {
  switch (kind) {
    case Buzz.selection:
      HapticFeedback.selectionClick();
    case Buzz.light:
      HapticFeedback.lightImpact();
    case Buzz.medium:
      HapticFeedback.mediumImpact();
    case Buzz.heavy:
      HapticFeedback.heavyImpact();
  }
}
