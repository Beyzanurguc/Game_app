# Foxium

Çocuklar için bulmaca oyunları ve bilgi kartı albümü. Flutter ile yazıldı;
ilerleme Firebase (anonim giriş + Firestore) üzerinde tutulur.

## İçerik

- **Oyunlar:** Tetris, Sudoku, Blok Patlat, Quiz, Yapboz
- **Bilgi kartları:** Oyun bitince kart kazanılır, albümde toplanır
- **Rozetler ve tilki atölyesi:** Yıldızlarla aksesuar alınıp maskota takılır
- **Ebeveyn ayarları:** Günlük oyun hakkı, titreşim, çıkış — yetişkin kapısının
  arkasında

## Geliştirme

```bash
flutter pub get
flutter run
```

Testler ve statik analiz:

```bash
flutter test
```

```bash
flutter analyze
```

Uygulama ikonunu yeniden üretmek için (önce kaynak görseller, sonra
platform dosyaları):

```bash
python tools/build_icon_sources.py
```

```bash
dart run flutter_launcher_icons
```

Android'de ikonu elle düzenlemek gerekirse Android Studio'nun Image Asset
sihirbazını kullanma: ürettiği `.webp` dosyaları `flutter_launcher_icons`'ın
`.png` çıktılarıyla aynı adı taşıdığı için derlemede "duplicate resource"
hatası verir, üstelik varsayılan ölçeğiyle ikon küçük görünür. Ölçüyü
değiştirmek istersen `tools/build_icon_sources.py` içindeki oranları düzenle.

## Firebase

Proje: `foxy-f429b`. Bilgi kartları ve yapbozlar Firestore'da tutulduğu için
ilk açılışta internet gerekir.

- Android yapılandırması `android/app/google-services.json` içinde ve depoda.
- **iOS eksik:** `ios/Runner/GoogleService-Info.plist` yok. Firebase konsolundan
  indirilip Xcode ile Runner hedefine eklenmeli, yoksa iOS derlemesi Firebase'e
  bağlanamaz.
- Firestore kuralları `firestore.rules` içinde; içerik yalnızca oturum açmış
  kullanıcılarca okunur, istemci hiçbir koşulda yazamaz.
- İçerik yüklemek için `tools/seed_firestore.js` (servis hesabı anahtarı ister;
  anahtarlar `.gitignore`'da).

## Yayın derlemesi (Android)

Release derlemesi `android/key.properties` varsa onunla, yoksa debug anahtarıyla
imzalanır. Play Store'a yüklenecek derleme için anahtar deposu gerekir:

```bash
keytool -genkey -v -keystore ~/foxy-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias foxy
```

Sonra `android/key.properties` dosyasını oluştur (bu dosya `.gitignore`'da,
depoya girmez):

```properties
storeFile=C:/Users/<kullanici>/foxy-release.jks
storePassword=<parola>
keyAlias=foxy
keyPassword=<parola>
```

```bash
flutter build appbundle --release
```

**Yayından önce:** `applicationId` hâlâ `com.example.game_app`. Play Store bu
öneki kabul etmez; değiştirildiğinde Firebase konsolunda yeni paket adıyla bir
Android uygulaması kaydedilip `google-services.json` yenilenmeli.
