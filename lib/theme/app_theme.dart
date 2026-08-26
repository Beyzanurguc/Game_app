import 'package:flutter/material.dart';

/// Foxwood Playful Learning — DESIGN.md içindeki renk belirteçleri.
///
/// Saf siyah/beyaz kullanılmaz; metin ve kenarlıklar sıcak kahve tonlarındadır.
abstract final class AppColors {
  // Yüzeyler
  static const background = Color(0xFFFFF8F6);
  static const surface = Color(0xFFFFF8F6);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFFF1EB);
  static const surfaceContainer = Color(0xFFFFEAE0);
  static const surfaceContainerHigh = Color(0xFFF9E4DA);
  static const surfaceContainerHighest = Color(0xFFF3DED5);
  static const creamBg = Color(0xFFFFFBF5);

  // Metin ve çizgiler
  static const onSurface = Color(0xFF241914);
  static const onSurfaceVariant = Color(0xFF574238);
  static const outline = Color(0xFF8A7266);
  static const outlineVariant = Color(0xFFDEC1B3);
  static const earthBrown = Color(0xFF5C4033);

  // Marka renkleri (maskottan türetildi)
  static const primary = Color(0xFF9C4400);
  static const foxOrange = Color(0xFFF47D31);
  static const primaryFixed = Color(0xFFFFDBCA);
  static const onPrimaryFixedVariant = Color(0xFF773200);
  static const bandanaTeal = Color(0xFF6DA1A1);
  static const secondary = Color(0xFF326667);
  static const secondaryContainer = Color(0xFFB4EAE9);
  static const sunnyYellow = Color(0xFFFFD152);
  static const berryPink = Color(0xFFF26D85);
  static const tertiary = Color(0xFF006687);
  static const tertiaryContainer = Color(0xFF00AADF);

  // Oyun blok renkleri (Tetris parçaları)
  static const leafGreen = Color(0xFF62B36B);
  static const plum = Color(0xFF9B72C9);

  // Hata durumları
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
}

/// 8px ritmine oturan boşluk ölçeği.
abstract final class AppSpacing {
  static const base = 8.0;
  static const gutter = 24.0;
  static const marginMobile = 16.0;
  static const marginDesktop = 40.0;
  static const touchTarget = 48.0;
}

/// Köşe yarıçapları — tasarımda keskin köşe yok.
abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 36.0;
}

/// Sora tipografisi.
///
/// Fontu projeye eklemek için `assets/fonts/` altına Sora dosyalarını koyup
/// pubspec.yaml içindeki `fonts:` bölümünü açman yeterli; eklenmezse Flutter
/// sessizce varsayılan sistem fontuna düşer.
abstract final class AppText {
  static const family = 'Sora';

  static const displayLg = TextStyle(
    fontFamily: family,
    fontSize: 48,
    height: 56 / 48,
    letterSpacing: -0.96,
    fontWeight: FontWeight.w800,
  );
  static const headlineLg = TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
  );
  static const headlineMd = TextStyle(
    fontFamily: family,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );
  static const titleMd = TextStyle(
    fontFamily: family,
    fontSize: 19,
    height: 26 / 19,
    fontWeight: FontWeight.w700,
  );
  static const bodyLg = TextStyle(
    fontFamily: family,
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w500,
  );
  static const bodyMd = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
  );
  static const labelLg = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.7,
    fontWeight: FontWeight.w600,
  );
  static const labelSm = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 16 / 11,
    letterSpacing: 0.4,
    fontWeight: FontWeight.w600,
  );
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.foxOrange,
    surface: AppColors.surface,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppText.family,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: const TextTheme(
      displayLarge: AppText.displayLg,
      headlineLarge: AppText.headlineLg,
      headlineMedium: AppText.headlineMd,
      titleMedium: AppText.titleMd,
      bodyLarge: AppText.bodyLg,
      bodyMedium: AppText.bodyMd,
      labelLarge: AppText.labelLg,
      labelSmall: AppText.labelSm,
    ).apply(bodyColor: AppColors.onSurface, displayColor: AppColors.onSurface),
  );
}
