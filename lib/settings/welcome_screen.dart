import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/squishy.dart';
import 'app_settings.dart';
import 'settings_controls.dart';
import 'settings_storage.dart';

/// Uygulama ilk açıldığında gelen giriş sayfası.
///
/// Yalnızca iki bilgi toplanır: çocuğun adı (isteğe bağlı) ve ebeveynin
/// belirlediği günlük oyun limiti. Kaydedildiğinde [AppSettings.onboarded]
/// true olur ve uygulama ana sayfaya geçer.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();

  /// Sürgünün anlık değeri; kaydederken tam sayıya yuvarlanır.
  double _limit = defaultDailyGameLimit.toDouble();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _start() {
    FocusScope.of(context).unfocus();
    AppSettingsScope.of(context).completeOnboarding(
      name: _nameController.text,
      dailyGameLimit: _limit.round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.base * 2,
                      AppSpacing.marginMobile,
                      AppSpacing.base * 2,
                    ),
                    children: [
                      const Center(child: Mascot(size: 120)),
                      const SizedBox(height: AppSpacing.base * 1.5),
                      Text(
                        'Hoş geldin!',
                        textAlign: TextAlign.center,
                        style: AppText.headlineLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Başlamadan önce iki küçük sorumuz var.',
                        textAlign: TextAlign.center,
                        style: AppText.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.gutter),
                      _NameCard(controller: _nameController),
                      const SizedBox(height: AppSpacing.base * 2),
                      _ParentCard(
                        limit: _limit,
                        onChanged: (value) => setState(() => _limit = value),
                      ),
                    ],
                  ),
                ),
                _StartArea(onStart: _start),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Adın ne?" kutusu — boş bırakılabilir, yalnızca harf kabul eder.
class _NameCard extends StatelessWidget {
  const _NameCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return DepthBox(
      color: AppColors.creamBg,
      depthColor: AppColors.surfaceContainerHighest,
      borderColor: AppColors.foxOrange,
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_emotions_rounded,
                color: AppColors.foxOrange,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Adın ne?',
                style: AppText.titleMd.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'İstersen boş bırakabilirsin, yine de birlikte oynarız.',
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ChildNameField(
            fieldKey: const ValueKey('welcome_name'),
            controller: controller,
          ),
        ],
      ),
    );
  }
}

/// "Ebeveyne sor" kutusu — günlük oyun limitini belirleyen sürgü.
class _ParentCard extends StatelessWidget {
  const _ParentCard({required this.limit, required this.onChanged});

  final double limit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return DepthBox(
      color: AppColors.secondaryContainer,
      depthColor: const Color(0xFF8FC9C8),
      borderColor: AppColors.bandanaTeal,
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                color: AppColors.secondary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Ebeveyne sor',
                style: AppText.titleMd.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Günde en fazla kaç oyun oynanabilir?',
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          DailyLimitSlider(
            limit: limit,
            onChanged: onChanged,
            valueKey: const ValueKey('welcome_limit_value'),
            sliderKey: const ValueKey('welcome_limit_slider'),
          ),
        ],
      ),
    );
  }
}

/// Alt sabit buton alanı — sürgü uzun olsa da düğme ekranda kalır.
class _StartArea extends StatelessWidget {
  const _StartArea({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        14,
        AppSpacing.marginMobile,
        14,
      ),
      child: Squishy(
        key: const ValueKey('welcome_start'),
        onTap: onStart,
        color: AppColors.foxOrange,
        depthColor: AppColors.primary,
        radius: AppRadius.md,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Center(
          child: Text(
            'HADİ BAŞLAYALIM',
            style: AppText.labelLg.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
