import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
