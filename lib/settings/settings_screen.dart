import 'package:flutter/material.dart';

import '../profile/fox_avatar.dart';
import '../profile/player_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/squishy.dart';
import 'app_settings.dart';
import 'settings_controls.dart';
import 'settings_storage.dart';

/// Ayarlar sayfası: adı ve günlük oyun limitini sonradan değiştirmek için.
///
/// Giriş sayfasıyla aynı iki bilgiyi düzenler ve aynı kutuları kullanır.
/// Değişiklikler kaydedilene kadar yalnızca sayfada durur; böylece sürgüyü
/// kurcalamak tek başına günlük hakkı bozmaz.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();

  /// Sürgünün anlık değeri; kaydederken tam sayıya yuvarlanır.
  double _limit = defaultDailyGameLimit.toDouble();

  /// Kutular kayıtlı değerlerle bir kez dolduruldu mu?
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;

    final settings = AppSettingsScope.of(context);
    _nameController.text = settings.childName;
    _limit = settings.dailyGameLimit.toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final settings = AppSettingsScope.of(context)
      ..updateChildName(_nameController.text)
      ..updateDailyGameLimit(_limit.round());

    // Ad temizlenmiş hâliyle kaydedildi; kutu da onu göstersin.
    _nameController.text = settings.childName;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          content: Text(
            'Ayarlar kaydedildi!',
            style: AppText.labelLg.copyWith(color: Colors.white),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                _SettingsHeader(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      4,
                      AppSpacing.marginMobile,
                      AppSpacing.base * 2,
                    ),
                    children: [
                      _NameCard(controller: _nameController),
                      const SizedBox(height: AppSpacing.base * 2),
                      _LimitCard(
                        limit: _limit,
                        playsToday: settings.playsToday,
                        onChanged: (value) => setState(() => _limit = value),
                      ),
                    ],
                  ),
                ),
                _SaveArea(onSave: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Başlık çubuğu — geri düğmesi, sayfa adı ve tilki.
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, AppSpacing.marginMobile, 12),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('settings_back'),
            onTap: onBack,
            child: Container(
              height: AppSpacing.touchTarget,
              width: AppSpacing.touchTarget,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Ayarlar',
              style: AppText.headlineLg.copyWith(color: AppColors.primary),
            ),
          ),
          FoxAvatar(
            size: 52,
            items: PlayerProfileScope.of(context).equippedItems,
          ),
        ],
      ),
    );
  }
}

/// Ad kutusu — boşaltılırsa uygulama adsız selamlamaya döner.
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
                'İsim',
                style: AppText.titleMd.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ana sayfada bu adla selamlanırsın. Boş bırakırsan adsız devam '
            'ederiz.',
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ChildNameField(
            fieldKey: const ValueKey('settings_name'),
            controller: controller,
          ),
        ],
      ),
    );
  }
}

/// Günlük oyun limiti kutusu — sürgü ve bugünkü durumun özeti.
class _LimitCard extends StatelessWidget {
  const _LimitCard({
    required this.limit,
    required this.playsToday,
    required this.onChanged,
  });

  final double limit;

  /// Bugün başlanan tur sayısı; yeni sınırın etkisini anlatmak için.
  final int playsToday;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    // Sınır bugün oynananın altına çekilirse hak bugünlük biter; ebeveyn
    // bunu kaydetmeden önce görsün.
    final endsToday = playsToday > 0 && playsToday >= limit.round();

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
              Expanded(
                child: Text(
                  'Günlük oyun hakkı',
                  style: AppText.titleMd.copyWith(color: AppColors.secondary),
                ),
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
            valueKey: const ValueKey('settings_limit_value'),
            sliderKey: const ValueKey('settings_limit_slider'),
          ),
          const SizedBox(height: 12),
          _TodayNote(playsToday: playsToday, endsToday: endsToday),
        ],
      ),
    );
  }
}

/// Bugünkü sayacın yeni sınırla ne olacağını anlatan not.
class _TodayNote extends StatelessWidget {
  const _TodayNote({required this.playsToday, required this.endsToday});

  final int playsToday;
  final bool endsToday;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (playsToday == 0) {
      text = 'Bugün henüz oyun oynanmadı.';
    } else if (endsToday) {
      text =
          'Bugün $playsToday oyun oynandı; bu sınırla bugünlük hak biter, '
          'yarın yeniden başlar.';
    } else {
      text = 'Bugün $playsToday oyun oynandı.';
    }

    return Row(
      key: const ValueKey('settings_today_note'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          endsToday ? Icons.info_rounded : Icons.today_rounded,
          size: 18,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppText.bodyMd.copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}

/// Alt sabit kaydetme alanı — giriş sayfasındaki düğmeyle aynı yerde.
class _SaveArea extends StatelessWidget {
  const _SaveArea({required this.onSave});

  final VoidCallback onSave;

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
        key: const ValueKey('settings_save'),
        onTap: onSave,
        color: AppColors.foxOrange,
        depthColor: AppColors.primary,
        radius: AppRadius.md,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Center(
          child: Text(
            'KAYDET',
            style: AppText.labelLg.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
