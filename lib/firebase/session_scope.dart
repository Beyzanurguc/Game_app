import 'package:flutter/widgets.dart';

import '../cards/card_storage.dart';
import '../profile/profile_storage.dart';
import '../settings/settings_storage.dart';

/// Cihazda tutulan her şeyi başlangıç durumuna döndürür.
///
/// Çıkışta gerekli: yeni anonim hesap boş bir buluta bakacağı için, yerel
/// önbellek temizlenmezse [FirestoreCardStorage] eski ilerlemeyi yeni `uid`
/// altına geri yükler ve çıkış hiçbir işe yaramaz. Ayarlar da (ad, günlük
/// limit) burada sıfırlanır; böylece uygulama giriş sayfasına döner.
Future<void> clearLocalState() async {
  await SharedPreferencesCardStorage().persist((
    collected: <String>{},
    stars: 0,
  ));
  await SharedPreferencesProfileStorage().persist(const StoredProfile());
  await SharedPreferencesSettingsStorage().persist(const StoredSettings());
}

/// Oturumu kapatma yeteneğini widget ağacına dağıtır.
///
/// Çıkış açılış akışını (giriş → içerik indirme) baştan çalıştırdığı için
/// yalnızca o akışı yöneten taraf gerçekleştirebilir; ayarlar sayfası
/// düğmeyi gösterir, işi buradan aldığı geri çağrıya devreder.
class SessionScope extends InheritedWidget {
  const SessionScope({
    super.key,
    required this.onSignOut,
    required super.child,
  });

  /// Oturumu kapatır ve uygulamayı giriş sayfasına döndürür.
  final Future<void> Function() onSignOut;

  /// Kapsam yoksa `null` döner: testler ve önizleme çıkış düğmesi olmadan
  /// çalışabilsin diye zorunlu tutulmadı.
  static SessionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>();

  @override
  bool updateShouldNotify(SessionScope oldWidget) =>
      onSignOut != oldWidget.onSignOut;
}
