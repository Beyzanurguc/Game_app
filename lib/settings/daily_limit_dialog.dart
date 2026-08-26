import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/squishy.dart';
import 'app_settings.dart';

/// Yeni bir tur başlatmadan önce günlük hakkı kontrol eder.
///
/// Hak varsa turu sayıp true döner. Hak bittiyse uyarıyı gösterir ve false
/// döner; çağıran taraf turu başlatmaz.
Future<bool> ensurePlayAllowed(BuildContext context) async {
  final settings = AppSettingsScope.of(context);
  if (settings.canPlay) {
    settings.recordPlay();
    return true;
  }

  await showDialog<void>(
    context: context,
    builder: (context) => _DailyLimitDialog(limit: settings.dailyGameLimit),
  );
  return false;
}

/// Günlük oyun hakkı bitince gösterilen uyarı.
class _DailyLimitDialog extends StatelessWidget {
  const _DailyLimitDialog({required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.gutter),
      child: DepthBox(
        color: AppColors.creamBg,
        depthColor: AppColors.surfaceContainerHighest,
        borderColor: AppColors.bandanaTeal,
        radius: AppRadius.lg,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 100, mood: MascotMood.sad),
            const SizedBox(height: 10),
            Text(
              'Bugünlük bu kadar!',
              textAlign: TextAlign.center,
              style: AppText.headlineMd.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Bugün $limit oyun hakkını kullandın. Yarın yeniden '
              'başlıyoruz — albümündeki kartlara göz atabilirsin.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Squishy(
              key: const ValueKey('daily_limit_ok'),
              onTap: () => Navigator.of(context).pop(),
              color: AppColors.foxOrange,
              depthColor: AppColors.primary,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: Text(
                  'TAMAM',
                  style: AppText.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
